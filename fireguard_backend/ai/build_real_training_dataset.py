from pathlib import Path
import numpy as np
import pandas as pd
import xarray as xr
from scipy.spatial import cKDTree

BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "data"

POSITIVE_FILE = DATA_DIR / "nasa_era5_fire_observations_2026.csv"
ERA5_FILE = DATA_DIR / "era5_land_2026_fireguard.nc"
OUTPUT_FILE = DATA_DIR / "fireguard_training_dataset.csv"

print("Loading real NASA + ERA5 observations...")

positive = pd.read_csv(POSITIVE_FILE, parse_dates=["datetime"])

positive["datetime"] = pd.to_datetime(
    positive["datetime"],
    utc=True
)

positive = positive[
    [
        "latitude",
        "longitude",
        "datetime",
        "era5_t2m_c",
        "era5_d2m_c",
        "era5_wind_speed_ms",
        "era5_precip_m",
    ]
].dropna().copy()

positive = positive[
    (positive["datetime"] >= pd.Timestamp("2026-09-02 00:00:00", tz="UTC")) &
    (positive["datetime"] <= pd.Timestamp("2026-09-05 16:00:00", tz="UTC"))
].reset_index(drop=True)

print("REAL POSITIVE OBSERVATIONS WITHIN ERA5 COVERAGE:", len(positive))

if len(positive) == 0:
    raise ValueError("No positive observations overlap ERA5 coverage.")

print("Loading ERA5 grid...")

ds = xr.open_dataset(ERA5_FILE)

times = pd.DatetimeIndex(
    pd.to_datetime(ds["valid_time"].values, utc=True)
)

lats = ds["latitude"].values
lons = ds["longitude"].values

# ---------------------------------------------------------------
# Build Botswana ERA5 background candidates.
# ---------------------------------------------------------------

lat_mask = (lats >= -27) & (lats <= -17)
lon_mask = (lons >= 20) & (lons <= 29)

selected_lats = lats[lat_mask]
selected_lons = lons[lon_mask]

time_grid, lat_grid, lon_grid = np.meshgrid(
    times,
    selected_lats,
    selected_lons,
    indexing="ij"
)

background = pd.DataFrame({
    "datetime": time_grid.ravel(),
    "latitude": lat_grid.ravel(),
    "longitude": lon_grid.ravel(),
})

print("ERA5 BOTSWANA CANDIDATES:", len(background))

# ---------------------------------------------------------------
# Controlled background selection.
#
# Background must be:
#   - >= 0.4 degrees from nearest NASA positive
#   - >= 1 hour from nearest NASA positive
#
# Class 0 therefore means controlled background / no FIRMS
# detection under these selection rules.
# ---------------------------------------------------------------

positive_times = positive["datetime"].astype("int64").to_numpy()
background_times = background["datetime"].astype("int64").to_numpy()

positive_times_sorted = np.sort(positive_times)

idx = np.searchsorted(
    positive_times_sorted,
    background_times,
    side="left"
)

idx_left = np.clip(idx - 1, 0, len(positive_times_sorted) - 1)
idx_right = np.clip(idx, 0, len(positive_times_sorted) - 1)

nearest_time_ns = np.minimum(
    np.abs(background_times - positive_times_sorted[idx_left]),
    np.abs(background_times - positive_times_sorted[idx_right])
)

nearest_time_hours = nearest_time_ns / 3_600_000_000_000.0

print("Calculating spatial separation efficiently...")

lat_scale = 111.32
mean_lat = background["latitude"].mean()
lon_scale = 111.32 * np.cos(np.radians(mean_lat))

positive_xy = np.column_stack([
    positive["latitude"].to_numpy() * lat_scale,
    positive["longitude"].to_numpy() * lon_scale,
])

background_xy = np.column_stack([
    background["latitude"].to_numpy() * lat_scale,
    background["longitude"].to_numpy() * lon_scale,
])

tree = cKDTree(positive_xy)

nearest_distance_km, _ = tree.query(
    background_xy,
    k=1,
    workers=-1
)

nearest_distance_degrees = nearest_distance_km / 111.32

keep = (
    (nearest_distance_degrees >= 0.4) &
    (nearest_time_hours >= 1.0)
)

background = background.loc[keep].reset_index(drop=True)

print("CONTROLLED BACKGROUND CANDIDATES:", len(background))

if len(background) == 0:
    raise ValueError("No controlled background observations remained.")

# ---------------------------------------------------------------
# Balance background against positive observations.
# ---------------------------------------------------------------

n_positive = len(positive)
n_background = min(len(background), n_positive)

background = background.sample(
    n=n_background,
    random_state=42
).reset_index(drop=True)

print("SELECTED CONTROLLED BACKGROUND:", len(background))

# ---------------------------------------------------------------
# Vectorized ERA5 feature extraction.
# ---------------------------------------------------------------

print("Extracting ERA5 features efficiently...")

era5_time_ns = times.astype("int64").to_numpy()
background_time_ns = background["datetime"].astype("int64").to_numpy()

time_indices = np.abs(
    era5_time_ns[:, None] - background_time_ns[None, :]
).argmin(axis=0)

lat_indices = np.abs(
    lats[:, None] - background["latitude"].to_numpy()[None, :]
).argmin(axis=0)

lon_indices = np.abs(
    lons[:, None] - background["longitude"].to_numpy()[None, :]
).argmin(axis=0)

t2m = ds["t2m"].values
d2m = ds["d2m"].values
u10 = ds["u10"].values
v10 = ds["v10"].values
tp = ds["tp"].values

background["era5_t2m_c"] = (
    t2m[time_indices, lat_indices, lon_indices] - 273.15
)

background["era5_d2m_c"] = (
    d2m[time_indices, lat_indices, lon_indices] - 273.15
)

background["era5_wind_speed_ms"] = np.sqrt(
    u10[time_indices, lat_indices, lon_indices] ** 2 +
    v10[time_indices, lat_indices, lon_indices] ** 2
)

background["era5_precip_m"] = (
    tp[time_indices, lat_indices, lon_indices]
)

# ---------------------------------------------------------------
# Create labels.
# ---------------------------------------------------------------

positive["fire_event"] = 1
background["fire_event"] = 0

columns = [
    "latitude",
    "longitude",
    "datetime",
    "era5_t2m_c",
    "era5_d2m_c",
    "era5_wind_speed_ms",
    "era5_precip_m",
    "fire_event",
]

positive = positive[columns]
background = background[columns]

training = pd.concat(
    [positive, background],
    ignore_index=True
).sample(
    frac=1,
    random_state=42
).reset_index(drop=True)

# ---------------------------------------------------------------
# Final validation before writing.
# ---------------------------------------------------------------

if training.isna().any().any():
    raise ValueError(
        "Training dataset contains NULL values."
    )

if training.duplicated().any():
    raise ValueError(
        "Training dataset contains exact duplicate rows."
    )

class_counts = training["fire_event"].value_counts().sort_index()

if set(class_counts.index) != {0, 1}:
    raise ValueError(
        "Training dataset must contain both classes 0 and 1."
    )

training.to_csv(OUTPUT_FILE, index=False)

ds.close()

print()
print("========================================")
print("FIREGUARD TRAINING DATASET CREATED")
print("========================================")
print("OUTPUT:", OUTPUT_FILE)
print("ROWS:", len(training))
print("COLUMNS:", list(training.columns))
print()
print("CLASS COUNTS:")
print(class_counts.to_string())
print()
print("CLASS NAMES:")
print("0 = controlled background / no FIRMS detection")
print("1 = NASA FIRMS fire-associated observation")
print()
print("NULL VALUES:")
print(training.isna().sum().to_string())
print()
print("EXACT DUPLICATES:", int(training.duplicated().sum()))
print()
print("DATASET READY FOR MODEL TRAINING: YES")
