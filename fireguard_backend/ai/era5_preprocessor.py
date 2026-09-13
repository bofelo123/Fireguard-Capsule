"""
FireGuard Capsule™
ERA5-Land Environmental Data Preprocessor
"""

from __future__ import annotations

from pathlib import Path
from math import exp, sqrt

import xarray as xr


DATA_FILE = (
    Path(__file__).resolve().parent
    / "data"
    / "era5_land_2025.nc"
)

BOTSWANA_LATITUDE_MIN = -27.0
BOTSWANA_LATITUDE_MAX = -17.0
BOTSWANA_LONGITUDE_MIN = 20.0
BOTSWANA_LONGITUDE_MAX = 30.0


def kelvin_to_celsius(value: float) -> float:
    return float(value) - 273.15


def calculate_relative_humidity(
    temperature_c: float,
    dewpoint_c: float,
) -> float:

    saturation_vapor_pressure = 6.112 * exp(
        (17.67 * temperature_c)
        / (temperature_c + 243.5)
    )

    actual_vapor_pressure = 6.112 * exp(
        (17.67 * dewpoint_c)
        / (dewpoint_c + 243.5)
    )

    humidity = (
        100.0
        * actual_vapor_pressure
        / saturation_vapor_pressure
    )

    return max(0.0, min(100.0, humidity))


def calculate_wind_speed(
    u10: float,
    v10: float,
) -> float:

    return sqrt(
        float(u10) ** 2
        + float(v10) ** 2
    )


def load_era5_environment() -> dict[str, float]:

    if not DATA_FILE.exists():
        raise FileNotFoundError(
            f"ERA5-Land dataset not found: {DATA_FILE}"
        )

    ds = xr.open_dataset(DATA_FILE)

    botswana = ds.sel(
        latitude=slice(
            BOTSWANA_LATITUDE_MAX,
            BOTSWANA_LATITUDE_MIN,
        ),
        longitude=slice(
            BOTSWANA_LONGITUDE_MIN,
            BOTSWANA_LONGITUDE_MAX,
        ),
    )

    temperature_k = float(
        botswana.t2m.mean().values
    )

    dewpoint_k = float(
        botswana.d2m.mean().values
    )

    u10 = float(
        botswana.u10.mean().values
    )

    v10 = float(
        botswana.v10.mean().values
    )

    precipitation_m = float(
        botswana.tp.mean().values
    )

    temperature_c = kelvin_to_celsius(
        temperature_k
    )

    dewpoint_c = kelvin_to_celsius(
        dewpoint_k
    )

    relative_humidity = calculate_relative_humidity(
        temperature_c,
        dewpoint_c,
    )

    wind_speed = calculate_wind_speed(
        u10,
        v10,
    )

    precipitation_mm = (
        precipitation_m * 1000.0
    )

    return {
        "temperature_c": round(
            temperature_c,
            2,
        ),
        "dewpoint_c": round(
            dewpoint_c,
            2,
        ),
        "relative_humidity_percent": round(
            relative_humidity,
            2,
        ),
        "wind_speed_mps": round(
            wind_speed,
            2,
        ),
        "precipitation_mm": round(
            precipitation_mm,
            4,
        ),
    }
