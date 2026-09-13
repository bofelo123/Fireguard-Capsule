from pathlib import Path

import cdsapi


# ============================================================
# FIREGUARD — ERA5-LAND 2026 CONTINUATION DOWNLOAD
# ============================================================
#
# Downloads the remaining real ERA5-Land hourly observations
# needed to complete the FireGuard NASA VIIRS observation
# period.
#
# Existing ERA5 files are NOT modified.
# ============================================================


BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "data"

OUTPUT_FILE = (
    DATA_DIR
    / "era5_land_2026_fireguard_continuation.nc"
)


DATA_DIR.mkdir(parents=True, exist_ok=True)


client = cdsapi.Client()


print("=" * 60)
print("FireGuard ERA5-Land 2026 Continuation Download")
print("=" * 60)

print(f"Output file:")
print(OUTPUT_FILE)

print()
print("Requesting:")
print("  Dataset: ERA5-Land hourly")
print("  Period:  2026-09-05 17:00 to 2026-09-08 23:00")
print("  Area:    Southern Africa")
print("  Variables:")
print("    - 2m temperature")
print("    - 2m dewpoint temperature")
print("    - 10m u wind")
print("    - 10m v wind")
print("    - total precipitation")
print()


client.retrieve(
    "reanalysis-era5-land",
    {
        "variable": [
            "2m_temperature",
            "2m_dewpoint_temperature",
            "10m_u_component_of_wind",
            "10m_v_component_of_wind",
            "total_precipitation",
        ],
        "year": "2026",
        "month": "09",
        "day": [
            "05",
            "06",
            "07",
            "08",
        ],
        "time": [
            "00:00",
            "01:00",
            "02:00",
            "03:00",
            "04:00",
            "05:00",
            "06:00",
            "07:00",
            "08:00",
            "09:00",
            "10:00",
            "11:00",
            "12:00",
            "13:00",
            "14:00",
            "15:00",
            "16:00",
            "17:00",
            "18:00",
            "19:00",
            "20:00",
            "21:00",
            "22:00",
            "23:00",
        ],
        "data_format": "netcdf",
        "download_format": "unarchived",
        "area": [
            -34.0,
            10.0,
            -4.0,
            39.0,
        ],
    },
    str(OUTPUT_FILE),
)


print()
print("=" * 60)
print("CONTINUATION DOWNLOAD COMPLETE")
print("=" * 60)
print(f"Saved to: {OUTPUT_FILE}")