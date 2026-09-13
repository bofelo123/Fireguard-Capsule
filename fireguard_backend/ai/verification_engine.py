"""
FireGuard Capsule™
Real Fire Verification Engine

Combines:
1. FireGuard capsule AI sensor analysis
2. NASA FIRMS satellite fire evidence

This module does NOT generate sensor data.
It only evaluates data received from real system sources.
"""

from __future__ import annotations

from typing import Any


def verify_fire_event(
    ai_analysis: dict[str, Any],
    nasa_evidence: dict[str, Any],
) -> dict[str, Any]:
    """
    Combine FireGuard AI analysis with NASA FIRMS evidence.

    Returns the verification structure expected by the
    FireGuard Flutter Capsule Detail screen.
    """

    classification = str(
        ai_analysis.get("classification", "")
    ).upper()

    severity = str(
        ai_analysis.get("severity", "")
    ).upper()

    ai_confidence = float(
        ai_analysis.get("confidence", 0.0)
    )

    nasa_detections = int(
        nasa_evidence.get("nearby_fire_detections", 0)
    )

    nasa_evidence_level = str(
        nasa_evidence.get(
            "satellite_fire_evidence",
            "NONE_DETECTED",
        )
    ).upper()

    flame_detected = bool(
        ai_analysis.get("flame_detected", False)
    )

    # --------------------------------------------------------
    # Determine verification state
    # --------------------------------------------------------

    if classification == "CONFIRMED_FIRE":
        state = "verified"
    elif (
        classification in {"FIRE", "POSSIBLE_FIRE", "SUSPECTED_FIRE"}
        or severity in {"CRITICAL", "HIGH"}
    ):
        state = "suspected"
    elif nasa_detections > 0:
        state = "suspected"
    else:
        state = "monitoring"

    # --------------------------------------------------------
    # Determine detection source
    # --------------------------------------------------------

    sources = []

    if classification:
        sources.append("FireGuard Capsule AI")

    if nasa_detections > 0:
        sources.append("NASA FIRMS")

    if flame_detected:
        sources.append("Flame Sensor")

    detection_source = " + ".join(sources)

    if not detection_source:
        detection_source = "FireGuard Monitoring System"

    # --------------------------------------------------------
    # Combine confidence
    # --------------------------------------------------------

    verification_confidence = ai_confidence

    if nasa_evidence_level == "STRONG":
        verification_confidence = min(
            100.0,
            ai_confidence + 10.0,
        )
    elif nasa_evidence_level == "MODERATE":
        verification_confidence = min(
            100.0,
            ai_confidence + 5.0,
        )

    # --------------------------------------------------------
    # AI status
    # --------------------------------------------------------

    if state == "verified":
        ai_status = "FIRE VERIFIED"
    elif state == "suspected":
        ai_status = "FIRE SUSPECTED"
    else:
        ai_status = "MONITORING"

    # --------------------------------------------------------
    # Evidence
    # --------------------------------------------------------

    evidence = {}

    sensor_status = ai_analysis.get("sensor_status")

    if isinstance(sensor_status, dict):
        for key, value in sensor_status.items():
            evidence[str(key)] = str(value)

    if nasa_detections > 0:
        evidence["NASA FIRMS"] = nasa_evidence_level

    if flame_detected:
        evidence["flame"] = "DETECTED"

    # --------------------------------------------------------
    # Explanation
    # --------------------------------------------------------

    if state == "verified":
        explanation = (
            "FireGuard AI verified fire conditions from "
            "capsule sensor analysis."
        )

        if nasa_detections > 0:
            explanation += (
                f" NASA FIRMS also reports "
                f"{nasa_detections} nearby fire detection(s), "
                "providing independent satellite evidence."
            )

    elif state == "suspected":
        explanation = (
            "FireGuard detected conditions requiring "
            "fire verification."
        )

        if nasa_detections > 0:
            explanation += (
                f" NASA FIRMS reports "
                f"{nasa_detections} nearby fire detection(s)."
            )

    else:
        explanation = (
            "No sufficient fire evidence is currently "
            "available from the connected intelligence sources."
        )

    return {
        "state": state,
        "verificationTime": None,
        "detectionSource": detection_source,
        "aiStatus": ai_status,
        "confidenceScore": round(
            verification_confidence,
            2,
        ),
        "evidence": evidence,
        "explanation": explanation,
    }