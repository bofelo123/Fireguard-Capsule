"""
FireGuard Capsule™
Runtime ERA5 Environmental Data Provider
"""

from __future__ import annotations

from datetime import datetime, timezone
from math import sqrt
from pathlib import Path

import numpy as np
import xarray as xr


DATA_DIR = Path(__file__).resolve().parent / "data"

ERA5_FILES = [
    DATA_DIR / "era5_land_2026_fireguard.nc",
    DATA_DIR / "era5_land_2026_fireguard_continuation.nc",
]

ERA5_TIME_COORDINATE = "valid_time"

MAX_TIME_DISTANCE_HOURS = 1.0


def _kelvin_to_celsius(value: float) -> float:
    return float(value) - 273.15


def _calculate_wind_speed(
    u10: float,
    v10: float,
) -> float:
    return sqrt(
        float(u10) ** 2
        + float(v10) ** 2
    )


def _normalise_timestamp(
    timestamp: datetime,
) -> datetime:

    if timestamp.tzinfo is not None:
        timestamp = timestamp.astimezone(
            timezone.utc
        ).replace(tzinfo=None)

    return timestamp


def lookup_era5(
    *,
    latitude: float,
    longitude: float,
    timestamp: datetime,
) -> dict:

    timestamp = _normalise_timestamp(timestamp)

    requested_time = np.datetime64(
        timestamp,
        "ns",
    )

    datasets = [
        xr.open_dataset(path)
        for path in ERA5_FILES
        if path.exists()
    ]

    if not datasets:
        return {
            "status": "UNAVAILABLE",
            "reason": (
                "No real 2026 ERA5 datasets "
                "are available."
            ),
        }

    try:
        best_result = None
        best_distance = None

        for ds in datasets:

            if ERA5_TIME_COORDINATE not in ds.coords:
                continue

            if "latitude" not in ds.coords:
                continue

            if "longitude" not in ds.coords:
                continue

            lat_values = ds.latitude.values
            lon_values = ds.longitude.values

            if not (
                float(lat_values.min())
                <= latitude
                <= float(lat_values.max())
            ):
                continue

            if not (
                float(lon_values.min())
                <= longitude
                <= float(lon_values.max())
            ):
                continue

            time_values = ds[
                ERA5_TIME_COORDINATE
            ].values.astype("datetime64[ns]")

            time_differences = np.abs(
                time_values - requested_time
            )

            nearest_index = int(
                np.argmin(time_differences)
            )

            nearest_time = time_values[
                nearest_index
            ]

            distance_hours = float(
                np.abs(
                    nearest_time
                    - requested_time
                )
                / np.timedelta64(
                    1,
                    "h",
                )
            )

            if (
                distance_hours
                > MAX_TIME_DISTANCE_HOURS
            ):
                continue

            selected = ds.sel(
                {
                    ERA5_TIME_COORDINATE: nearest_time,
                    "latitude": latitude,
                    "longitude": longitude,
                },
                method="nearest",
            )

            t2m = float(
                selected["t2m"].values
            )

            d2m = float(
                selected["d2m"].values
            )

            u10 = float(
                selected["u10"].values
            )

            v10 = float(
                selected["v10"].values
            )

            tp = float(
                selected["tp"].values
            )

            result = {
                "status": "AVAILABLE",

                "requested_timestamp": (
                    timestamp.isoformat(
                        sep=" "
                    )
                ),

                "era5_timestamp": str(
                    nearest_time
                ),

                "latitude": float(
                    selected.latitude.values
                ),

                "longitude": float(
                    selected.longitude.values
                ),

                "era5_t2m_c": (
                    _kelvin_to_celsius(t2m)
                ),

                "era5_d2m_c": (
                    _kelvin_to_celsius(d2m)
                ),

                "era5_wind_speed_ms": (
                    _calculate_wind_speed(
                        u10,
                        v10,
                    )
                ),

                "era5_precip_m": tp,

                "time_distance_hours": (
                    distance_hours
                ),
            }

            if (
                best_distance is None
                or distance_hours < best_distance
            ):
                best_result = result
                best_distance = distance_hours

        if best_result is None:
            return {
                "status": "UNAVAILABLE",
                "reason": (
                    "No real ERA5 observation "
                    "is available within "
                    f"{MAX_TIME_DISTANCE_HOURS} "
                    "hour of the requested "
                    "capsule timestamp and "
                    "GPS position."
                ),
                "requested_timestamp": (
                    timestamp.isoformat(
                        sep=" "
                    )
                ),
                "latitude": latitude,
                "longitude": longitude,
            }

        return best_result

    finally:
        for ds in datasets:
            ds.close()