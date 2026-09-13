"""
FireGuard Capsule™
NASA FIRMS Fire Intelligence

This module analyzes REAL NASA FIRMS fire detections.
It does NOT create synthetic or mock fire data.

Important:
- NASA FIRMS data contains detected fire events.
- This module provides satellite evidence.
- It is NOT a fire/no-fire classifier.
"""

from __future__ import annotations

from pathlib import Path
from math import radians, sin, cos, sqrt, atan2
from typing import Any

import pandas as pd


# ============================================================
# CONFIGURATION
# ============================================================

DATA_FILE = (
    Path(__file__).resolve().parent
    / "data"
    / "nasa_fire_events.csv"
)


REQUIRED_COLUMNS = {
    "latitude",
    "longitude",
    "bright_ti4",
    "bright_ti5",
    "frp",
    "acq_date",
    "acq_time",
    "confidence",
    "daynight",
}


# ============================================================
# LOAD REAL NASA DATA
# ============================================================

def load_nasa_fire_events() -> pd.DataFrame:
    """
    Load the real NASA FIRMS fire-event dataset.

    Raises:
        FileNotFoundError:
            If the NASA dataset does not exist.

        ValueError:
            If required NASA columns are missing.
    """

    if not DATA_FILE.exists():
        raise FileNotFoundError(
            f"NASA FIRMS dataset not found: {DATA_FILE}"
        )

    df = pd.read_csv(DATA_FILE)

    missing_columns = REQUIRED_COLUMNS - set(df.columns)

    if missing_columns:
        raise ValueError(
            "NASA dataset is missing required columns: "
            + ", ".join(sorted(missing_columns))
        )

    return df


# ============================================================
# DISTANCE CALCULATION
# ============================================================

def haversine_distance_km(
    latitude_1: float,
    longitude_1: float,
    latitude_2: float,
    longitude_2: float,
) -> float:
    """
    Calculate the great-circle distance between two
    geographic coordinates in kilometres.
    """

    earth_radius_km = 6371.0088

    lat1 = radians(latitude_1)
    lat2 = radians(latitude_2)

    delta_lat = radians(latitude_2 - latitude_1)
    delta_lon = radians(longitude_2 - longitude_1)

    a = (
        sin(delta_lat / 2) ** 2
        + cos(lat1)
        * cos(lat2)
        * sin(delta_lon / 2) ** 2
    )

    c = 2 * atan2(sqrt(a), sqrt(1 - a))

    return earth_radius_km * c


# ============================================================
# NASA FIRE INTELLIGENCE
# ============================================================

def analyze_nasa_fire_activity(
    latitude: float,
    longitude: float,
    radius_km: float = 25.0,
) -> dict[str, Any]:
    """
    Analyze real NASA FIRMS fire detections around a location.

    Args:
        latitude:
            Latitude of the FireGuard capsule/location.

        longitude:
            Longitude of the FireGuard capsule/location.

        radius_km:
            Search radius in kilometres.

    Returns:
        Structured NASA satellite fire intelligence.
    """

    if not -90 <= latitude <= 90:
        raise ValueError("Latitude must be between -90 and 90.")

    if not -180 <= longitude <= 180:
        raise ValueError(
            "Longitude must be between -180 and 180."
        )

    if radius_km <= 0:
        raise ValueError("radius_km must be greater than zero.")

    df = load_nasa_fire_events().copy()

    # --------------------------------------------------------
    # Calculate geographic distance from requested location
    # --------------------------------------------------------

    df["distance_km"] = df.apply(
        lambda row: haversine_distance_km(
            latitude,
            longitude,
            float(row["latitude"]),
            float(row["longitude"]),
        ),
        axis=1,
    )

    nearby = df[df["distance_km"] <= radius_km].copy()

    # --------------------------------------------------------
    # No nearby NASA detections
    # --------------------------------------------------------

    if nearby.empty:
        return {
            "satellite_source": "NASA FIRMS",
            "data_file": DATA_FILE.name,
            "location": {
                "latitude": latitude,
                "longitude": longitude,
            },
            "search_radius_km": radius_km,
            "nearby_fire_detections": 0,
            "satellite_fire_evidence": "NONE_DETECTED",
            "maximum_frp": 0.0,
            "average_frp": 0.0,
            "maximum_bright_ti4": None,
            "average_bright_ti4": None,
            "average_bright_ti5": None,
            "nearest_detection_distance_km": None,
            "confidence_counts": {},
            "daynight_counts": {},
            "explanation": (
                "No NASA FIRMS fire detections were found "
                "within the requested search radius in the "
                "available dataset."
            ),
        }

    # --------------------------------------------------------
    # Numerical summaries
    # --------------------------------------------------------

    maximum_frp = float(nearby["frp"].max())
    average_frp = float(nearby["frp"].mean())

    maximum_bright_ti4 = float(
        nearby["bright_ti4"].max()
    )

    average_bright_ti4 = float(
        nearby["bright_ti4"].mean()
    )

    average_bright_ti5 = float(
        nearby["bright_ti5"].mean()
    )

    nearest_distance = float(
        nearby["distance_km"].min()
    )

    confidence_counts = (
        nearby["confidence"]
        .astype(str)
        .value_counts()
        .to_dict()
    )

    daynight_counts = (
        nearby["daynight"]
        .astype(str)
        .value_counts()
        .to_dict()
    )

    # --------------------------------------------------------
    # Evidence classification
    #
    # This is satellite evidence classification,
    # NOT a trained fire/no-fire prediction.
    # --------------------------------------------------------

    if maximum_frp >= 100:
        evidence = "STRONG"
    elif maximum_frp >= 20:
        evidence = "MODERATE"
    else:
        evidence = "DETECTED"

    # --------------------------------------------------------
    # Explanation
    # --------------------------------------------------------

    explanation = (
        f"NASA FIRMS detected {len(nearby)} fire event(s) "
        f"within {radius_km:.1f} km. "
        f"The nearest detection is "
        f"{nearest_distance:.2f} km away. "
        f"Maximum reported FRP is "
        f"{maximum_frp:.2f} MW."
    )

    return {
        "satellite_source": "NASA FIRMS",
        "data_file": DATA_FILE.name,
        "location": {
            "latitude": latitude,
            "longitude": longitude,
        },
        "search_radius_km": radius_km,
        "nearby_fire_detections": int(len(nearby)),
        "satellite_fire_evidence": evidence,
        "maximum_frp": round(maximum_frp, 2),
        "average_frp": round(average_frp, 2),
        "maximum_bright_ti4": round(
            maximum_bright_ti4,
            2,
        ),
        "average_bright_ti4": round(
            average_bright_ti4,
            2,
        ),
        "average_bright_ti5": round(
            average_bright_ti5,
            2,
        ),
        "nearest_detection_distance_km": round(
            nearest_distance,
            2,
        ),
        "confidence_counts": confidence_counts,
        "daynight_counts": daynight_counts,
        "explanation": explanation,
    }