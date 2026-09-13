from pathlib import Path
import pandas as pd
import xarray as xr
import numpy as np


# ============================================================
# FireGuard Capsule™
# Real Training Dataset Builder
#
# NASA FIRMS + ERA5-Land
#
# IMPORTANT:
# - No fake fire labels
# - No fake sensor readings
# - No global weather averages
# - NASA observations are matched to ERA5 by location and time
# ============================================================


BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "data"

NASA_FILE = DATA_DIR / "nasa_fire_events.csv"
ERA5_FILE = DATA_DIR / "era5_land_2025.nc"

OUTPUT_FILE = DATA_DIR / "fireguard_training_dataset.csv"


# Maximum spatial distance from the NASA fire point
# to the nearest ERA5 grid point.
MAX_DISTANCE_DEGREES = 0.2


def calculate_relative_humidity(
    temperature_c,
    dewpoint_c
):
    """
    Calculate relative humidity (%) from temperature
    and dewpoint temperature.
    """

    a = 17.625
    b = 243.04

    numerator = np.exp(
        (a * dewpoint_c) /
        (b + dewpoint_c)
    )

    denominator = np.exp(
        (a * temperature_c) /
        (b + temperature_c)
    )

    rh = 100.0 * numerator / denominator

    return np.clip(rh, 0.0, 100.0)


def calculate_wind_speed(
    u10,
    v10
):
    """
    Calculate 10 m wind speed from U/V components.
    """

    return np.sqrt(
        (u10 ** 2) +
        (v10 ** 2)
    )


def main():

    print("=" * 70)
    print("FireGuard Capsule™ - Real Training Dataset Builder")
    print("=" * 70)

    # --------------------------------------------------------
    # 1. Check files
    # --------------------------------------------------------

    print("\n[1/6] Checking real data files...")

    if not NASA_FILE.exists():
        raise FileNotFoundError(
            f"NASA FIRMS file not found:\n{NASA_FILE}"
        )

    if not ERA5_FILE.exists():
        raise FileNotFoundError(
            f"ERA5-Land file not found:\n{ERA5_FILE}"
        )

    print(f"NASA:  {NASA_FILE}")
    print(f"ERA5:  {ERA5_FILE}")

    # --------------------------------------------------------
    # 2. Read NASA FIRMS
    # --------------------------------------------------------

    print("\n[2/6] Reading real NASA FIRMS data...")

    nasa = pd.read_csv(NASA_FILE)

    required_nasa_columns = [
        "latitude",
        "longitude",
        "acq_date",
        "acq_time",
        "bright_ti4",
        "bright_ti5",
        "frp",
        "confidence",
        "satellite",
        "daynight",
        "fire_event",
    ]

    missing_nasa = [
        column
        for column in required_nasa_columns
        if column not in nasa.columns
    ]

    if missing_nasa:
        raise ValueError(
            "NASA dataset is missing columns:\n"
            + "\n".join(
                f" - {column}"
                for column in missing_nasa
            )
        )

    nasa["acq_date"] = pd.to_datetime(
        nasa["acq_date"],
        errors="coerce"
    )

    if nasa["acq_date"].isna().any():
        raise ValueError(
            "NASA dataset contains invalid dates."
        )

    # NASA acq_time is normally HHMM
    nasa["acq_time"] = (
        nasa["acq_time"]
        .astype(str)
        .str.zfill(4)
    )

    nasa["timestamp"] = pd.to_datetime(
        nasa["acq_date"].dt.strftime("%Y-%m-%d")
        + " "
        + nasa["acq_time"].str[:2]
        + ":"
        + nasa["acq_time"].str[2:4],
        errors="coerce"
    )

    if nasa["timestamp"].isna().any():
        raise ValueError(
            "NASA dataset contains invalid acquisition times."
        )

    print(
        f"NASA observations: {len(nasa):,}"
    )

    print(
        f"NASA period: "
        f"{nasa['timestamp'].min()} → "
        f"{nasa['timestamp'].max()}"
    )

    # --------------------------------------------------------
    # 3. Read ERA5-Land
    # --------------------------------------------------------

    print("\n[3/6] Reading real ERA5-Land data...")

    era = xr.open_dataset(
        ERA5_FILE
    )

    required_era5_variables = [
        "t2m",
        "d2m",
        "u10",
        "v10",
        "tp",
    ]

    missing_era5 = [
        variable
        for variable in required_era5_variables
        if variable not in era.data_vars
    ]

    if missing_era5:
        raise ValueError(
            "ERA5-Land dataset is missing variables:\n"
            + "\n".join(
                f" - {variable}"
                for variable in missing_era5
            )
        )

    print(
        f"ERA5 timestamps: {len(era.valid_time):,}"
    )

    print(
        f"ERA5 period: "
        f"{pd.Timestamp(era.valid_time.values.min())} → "
        f"{pd.Timestamp(era.valid_time.values.max())}"
    )

    # --------------------------------------------------------
    # 4. Check temporal overlap
    # --------------------------------------------------------

    print("\n[4/6] Checking temporal compatibility...")

    nasa_start = nasa["timestamp"].min()
    nasa_end = nasa["timestamp"].max()

    era_start = pd.Timestamp(
        era.valid_time.values.min()
    )

    era_end = pd.Timestamp(
        era.valid_time.values.max()
    )

    if nasa_end < era_start or era_end < nasa_start:

        print("\nWARNING:")
        print(
            "NASA FIRMS and ERA5-Land periods do not overlap."
        )

        print(
            "\nNo training dataset will be created."
        )

        print(
            "This is intentional."
        )

        print(
            "FireGuard will not match environmental "
            "conditions from the wrong year."
        )

        print(
            "\nNo output file was created."
        )

        era.close()

        return

    # --------------------------------------------------------
    # 5. Prepare ERA5 environmental variables
    # --------------------------------------------------------

    print(
        "\n[5/6] Preparing spatially matched "
        "ERA5 environmental data..."
    )

    temperature_c = (
        era["t2m"] - 273.15
    )

    dewpoint_c = (
        era["d2m"] - 273.15
    )

    relative_humidity = calculate_relative_humidity(
        temperature_c,
        dewpoint_c
    )

    wind_speed = calculate_wind_speed(
        era["u10"],
        era["v10"]
    )

    precipitation_mm = (
        era["tp"] * 1000.0
    )

    # --------------------------------------------------------
    # Match each NASA fire observation to:
    #
    # 1. nearest ERA5 time
    # 2. nearest ERA5 location
    # --------------------------------------------------------

    records = []

    print(
        "\nMatching NASA fire observations "
        "to ERA5 conditions..."
    )

    for index, fire in nasa.iterrows():

        fire_time = fire["timestamp"]

        fire_lat = float(
            fire["latitude"]
        )

        fire_lon = float(
            fire["longitude"]
        )

        # Nearest ERA5 timestamp
        nearest_time = pd.Timestamp(
            era.valid_time.sel(
                valid_time=fire_time,
                method="nearest"
            ).values
        )

        # Reject matches that are too far away in time.
        time_difference = abs(
            nearest_time - fire_time
        )

        if time_difference > pd.Timedelta(
            hours=1
        ):
            continue

        # Select the nearest spatial ERA5 grid point.
        snapshot = era.sel(
            valid_time=nearest_time,
            latitude=fire_lat,
            longitude=fire_lon,
            method="nearest"
        )

        matched_lat = float(
            snapshot["latitude"].values
        )

        matched_lon = float(
            snapshot["longitude"].values
        )

        spatial_distance = np.sqrt(
            (matched_lat - fire_lat) ** 2
            +
            (matched_lon - fire_lon) ** 2
        )

        if spatial_distance > MAX_DISTANCE_DEGREES:
            continue

        record = {
            "latitude": fire_lat,
            "longitude": fire_lon,

            "bright_ti4": fire["bright_ti4"],
            "bright_ti5": fire["bright_ti5"],
            "frp": fire["frp"],
            "confidence": fire["confidence"],
            "satellite": fire["satellite"],
            "daynight": fire["daynight"],

            "fire_event": int(
                fire["fire_event"]
            ),

            "timestamp": fire_time,

            "era5_timestamp": nearest_time,

            "temperature_c": float(
                snapshot["t2m"].values - 273.15
            ),

            "dewpoint_c": float(
                snapshot["d2m"].values - 273.15
            ),

            "relative_humidity_percent": float(
                relative_humidity.sel(
                    valid_time=nearest_time,
                    latitude=fire_lat,
                    longitude=fire_lon,
                    method="nearest"
                ).values
            ),

            "wind_speed_mps": float(
                wind_speed.sel(
                    valid_time=nearest_time,
                    latitude=fire_lat,
                    longitude=fire_lon,
                    method="nearest"
                ).values
            ),

            "precipitation_mm": float(
                precipitation_mm.sel(
                    valid_time=nearest_time,
                    latitude=fire_lat,
                    longitude=fire_lon,
                    method="nearest"
                ).values
            ),
        }

        records.append(record)

    # --------------------------------------------------------
    # Final dataset
    # --------------------------------------------------------

    if not records:

        print(
            "\nNo valid NASA/ERA5 matches were found."
        )

        print(
            "No training dataset was created."
        )

        era.close()

        return

    training_df = pd.DataFrame(
        records
    )

    # Remove accidental duplicates
    training_df = training_df.drop_duplicates()

    training_df.to_csv(
        OUTPUT_FILE,
        index=False
    )

    era.close()

    print(
        "\n[6/6] Training dataset created successfully."
    )

    print(
        f"Rows: {len(training_df):,}"
    )

    print(
        f"Columns: {len(training_df.columns)}"
    )

    print(
        f"Saved to:\n{OUTPUT_FILE}"
    )

    print("\nDataset preview:")
    print(
        training_df.head()
    )

    print(
        "\nFireGuard real-data pipeline completed."
    )


if __name__ == "__main__":
    main()