from __future__ import annotations

from pathlib import Path
from typing import Any

# ============================================================
# FIREGUARD AI SENSOR INTELLIGENCE + ENVIRONMENTAL ML
# ============================================================
#
# FireGuard uses two separate real-data intelligence layers:
#
# 1. REAL CAPSULE SENSOR INTELLIGENCE
# - temperature
# - smoke
# - humidity
# - wind
# - MQ-2
# - MQ-7
# - infrared temperature
# - flame detection
#
# 2. REAL ENVIRONMENTAL MACHINE LEARNING
# - ERA5 2 m temperature
# - ERA5 2 m dewpoint
# - ERA5 wind speed
# - ERA5 precipitation
#
# The environmental ML model was trained using real NASA FIRMS
# fire-event observations matched with real ERA5 environmental
# conditions.
#
# IMPORTANT:
# - No mock sensor data is generated.
# - No synthetic sensor values are generated.
# - None means a sensor/environmental feature is unavailable.
# - UNAVAILABLE is different from NORMAL.
# - The capsule sensor intelligence remains separate from the
#   environmental ML model.
# - The calibrated environmental ML estimate is NOT claimed
#   to be an absolute physical probability of fire.
# - Environmental ML can contribute to SUSPECTED_FIRE through
#   deliberate decision fusion, but cannot alone declare
#   CONFIRMED_FIRE.
#
# ============================================================


# ============================================================
# ENGINE VERSION
# ============================================================

MODEL_STATUS = "REAL_SENSOR_INTELLIGENCE_V2_WITH_ENVIRONMENTAL_ML_V1"


# ============================================================
# CALIBRATED ENVIRONMENTAL ML MODEL
# ============================================================

MODEL_PATH = (
    Path(__file__).resolve().parent
    / "data"
    / "fireguard_calibrated_model.pkl"
)

_ENVIRONMENTAL_ML_PACKAGE: dict[str, Any] | None = None
_ENVIRONMENTAL_ML_LOAD_ERROR: str | None = None


# ============================================================
# ENVIRONMENTAL ML FEATURES
# ============================================================

ENVIRONMENTAL_ML_FEATURES = [
    "era5_t2m_c",
    "era5_d2m_c",
    "era5_wind_speed_ms",
    "era5_precip_m",
]


# ============================================================
# INITIAL ENGINEERING THRESHOLDS
# ============================================================
#
# These are initial engineering thresholds only.
# They must be calibrated against FireGuard's actual sensors
# and real field observations before being treated as validated
# operational thresholds.
# ============================================================

TEMPERATURE_ELEVATED = 50.0
TEMPERATURE_CRITICAL = 80.0

SMOKE_ELEVATED = 30.0
SMOKE_CRITICAL = 70.0

MQ2_ELEVATED = 200.0
MQ2_CRITICAL = 500.0

MQ7_ELEVATED = 150.0
MQ7_CRITICAL = 400.0

INFRARED_ELEVATED = 50.0
INFRARED_CRITICAL = 80.0

WIND_ELEVATED = 6.0
WIND_HIGH = 10.0

HUMIDITY_DRY = 40.0
HUMIDITY_VERY_DRY = 25.0


# ============================================================
# ENVIRONMENTAL ML MODEL LOADER
# ============================================================

def _load_environmental_ml_model() -> dict[str, Any]:
    """
    Load the calibrated FireGuard environmental ML package once.

    The package contains:
    - trained Random Forest model
    - isotonic probability calibrator
    - feature column definition
    - model metadata

    The model is loaded lazily rather than during module import.
    This keeps predictor import safe and makes the loading step
    explicit.
    """

    global _ENVIRONMENTAL_ML_PACKAGE
    global _ENVIRONMENTAL_ML_LOAD_ERROR

    if _ENVIRONMENTAL_ML_PACKAGE is not None:
        return _ENVIRONMENTAL_ML_PACKAGE

    if _ENVIRONMENTAL_ML_LOAD_ERROR is not None:
        raise RuntimeError(
            _ENVIRONMENTAL_ML_LOAD_ERROR
        )

    if not MODEL_PATH.exists():
        _ENVIRONMENTAL_ML_LOAD_ERROR = (
            "Calibrated environmental ML model was not found at "
            f"{MODEL_PATH}"
        )

        raise RuntimeError(
            _ENVIRONMENTAL_ML_LOAD_ERROR
        )

    try:
        import joblib

        package = joblib.load(MODEL_PATH)

    except Exception as exc:
        _ENVIRONMENTAL_ML_LOAD_ERROR = (
            "Failed to load the calibrated environmental ML model: "
            f"{exc}"
        )

        raise RuntimeError(
            _ENVIRONMENTAL_ML_LOAD_ERROR
        ) from exc

    if not isinstance(package, dict):
        _ENVIRONMENTAL_ML_LOAD_ERROR = (
            "The calibrated environmental ML package has an invalid format."
        )

        raise RuntimeError(
            _ENVIRONMENTAL_ML_LOAD_ERROR
        )

    required_keys = {
        "model",
        "calibrator",
        "feature_columns",
    }

    missing_keys = required_keys.difference(
        package.keys()
    )

    if missing_keys:
        _ENVIRONMENTAL_ML_LOAD_ERROR = (
            "The calibrated environmental ML package is missing "
            f"required keys: {sorted(missing_keys)}"
        )

        raise RuntimeError(
            _ENVIRONMENTAL_ML_LOAD_ERROR
        )

    feature_columns = list(
        package["feature_columns"]
    )

    if feature_columns != ENVIRONMENTAL_ML_FEATURES:
        _ENVIRONMENTAL_ML_LOAD_ERROR = (
            "Environmental ML feature mismatch. "
            f"Expected {ENVIRONMENTAL_ML_FEATURES}, "
            f"but model contains {feature_columns}."
        )

        raise RuntimeError(
            _ENVIRONMENTAL_ML_LOAD_ERROR
        )

    _ENVIRONMENTAL_ML_PACKAGE = package

    return _ENVIRONMENTAL_ML_PACKAGE


# ============================================================
# ENVIRONMENTAL ML INFERENCE
# ============================================================

def _run_environmental_ml(
    era5_t2m_c: float | None,
    era5_d2m_c: float | None,
    era5_wind_speed_ms: float | None,
    era5_precip_m: float | None,
) -> dict[str, Any]:
    """
    Run the calibrated environmental ML model only when all
    required ERA5 features are available.

    No environmental feature is inferred from another sensor.

    In particular:
    - capsule humidity is NOT converted into dewpoint
    - precipitation is NOT estimated
    - wind speed is NOT derived from capsule wind unless the
      actual ERA5 wind feature is supplied

    Therefore missing ERA5 data results in UNAVAILABLE rather
    than fabricated values.
    """

    values = {
        "era5_t2m_c": era5_t2m_c,
        "era5_d2m_c": era5_d2m_c,
        "era5_wind_speed_ms": era5_wind_speed_ms,
        "era5_precip_m": era5_precip_m,
    }

    unavailable = [
        name
        for name, value in values.items()
        if value is None
    ]

    if unavailable:

        return {
            "environmental_ml_status": "UNAVAILABLE",
            "environmental_ml_probability": None,
            "environmental_ml_raw_probability": None,
            "environmental_ml_features": values,
            "environmental_ml_unavailable_features": unavailable,
            "environmental_ml_model": None,
        }

    try:

        package = _load_environmental_ml_model()

        model = package["model"]
        calibrator = package["calibrator"]
        feature_columns = package["feature_columns"]

        import pandas as pd

        feature_row = pd.DataFrame(
            [
                {
                    "era5_t2m_c": era5_t2m_c,
                    "era5_d2m_c": era5_d2m_c,
                    "era5_wind_speed_ms": era5_wind_speed_ms,
                    "era5_precip_m": era5_precip_m,
                }
            ],
            columns=feature_columns,
        )

        raw_probability = float(
            model.predict_proba(
                feature_row
            )[0][1]
        )

        calibrated_probability = float(
            calibrator.predict(
                [raw_probability]
            )[0]
        )

        # Keep the calibrated value within the mathematical
        # probability interval.
        calibrated_probability = min(
            1.0,
            max(
                0.0,
                calibrated_probability,
            ),
        )

        return {
            "environmental_ml_status": "AVAILABLE",
            "environmental_ml_probability": calibrated_probability,
            "environmental_ml_raw_probability": raw_probability,
            "environmental_ml_features": values,
            "environmental_ml_unavailable_features": [],
            "environmental_ml_model": (
                "CALIBRATED_RANDOM_FOREST_ISOTONIC"
            ),
        }

    except Exception as exc:

        return {
            "environmental_ml_status": "ERROR",
            "environmental_ml_probability": None,
            "environmental_ml_raw_probability": None,
            "environmental_ml_features": values,
            "environmental_ml_unavailable_features": [],
            "environmental_ml_model": None,
            "environmental_ml_error": str(exc),
        }


# ============================================================
# VALIDATION
# ============================================================

def _validate_optional_number(
    name: str,
    value: float | None,
    minimum: float | None = None,
    maximum: float | None = None,
) -> float | None:

    if value is None:
        return None

    try:
        numeric_value = float(value)

    except (TypeError, ValueError) as exc:

        raise ValueError(
            f"{name} must be numeric."
        ) from exc

    if numeric_value != numeric_value:

        raise ValueError(
            f"{name} cannot be NaN."
        )

    if minimum is not None and numeric_value < minimum:

        raise ValueError(
            f"{name} cannot be less than {minimum}."
        )

    if maximum is not None and numeric_value > maximum:

        raise ValueError(
            f"{name} cannot be greater than {maximum}."
        )

    return numeric_value


def _validate_required_number(
    name: str,
    value: float,
    minimum: float | None = None,
    maximum: float | None = None,
) -> float:

    result = _validate_optional_number(
        name=name,
        value=value,
        minimum=minimum,
        maximum=maximum,
    )

    if result is None:

        raise ValueError(
            f"{name} is required."
        )

    return result


# ============================================================
# SENSOR STATUS HELPERS
# ============================================================

def _status(
    value: float | None,
    elevated: float,
    critical: float,
) -> str:

    if value is None:
        return "UNAVAILABLE"

    if value >= critical:
        return "CRITICAL"

    if value >= elevated:
        return "ELEVATED"

    return "NORMAL"


def _wind_status(
    value: float | None,
) -> str:

    if value is None:
        return "UNAVAILABLE"

    if value >= WIND_HIGH:
        return "HIGH"

    if value >= WIND_ELEVATED:
        return "ELEVATED"

    return "NORMAL"


def _humidity_status(
    value: float | None,
) -> str:

    if value is None:
        return "UNAVAILABLE"

    if value < HUMIDITY_VERY_DRY:
        return "VERY_DRY"

    if value < HUMIDITY_DRY:
        return "DRY"

    return "NORMAL"


# ============================================================
# MAIN FIREGUARD AI FUNCTION
# ============================================================

def predict_fire(
    temperature: float | None,
    smoke_level: float | None,
    humidity: float | None,
    wind_speed: float | None,
    mq2: float | None = None,
    mq7: float | None = None,
    infrared_temperature: float | None = None,
    flame_detected: bool | None = None,

    # Real ERA5 environmental ML features
    era5_t2m_c: float | None = None,
    era5_d2m_c: float | None = None,
    era5_wind_speed_ms: float | None = None,
    era5_precip_m: float | None = None,

) -> dict[str, Any]:

    # --------------------------------------------------------
    # Validate capsule environmental inputs (NOW OPTIONAL)
    # --------------------------------------------------------

    temperature = _validate_optional_number(
        "temperature",
        temperature,
    )

    smoke_level = _validate_optional_number(
        "smoke_level",
        smoke_level,
        minimum=0.0,
    )

    humidity = _validate_optional_number(
        "humidity",
        humidity,
        minimum=0.0,
        maximum=100.0,
    )

    wind_speed = _validate_optional_number(
        "wind_speed",
        wind_speed,
        minimum=0.0,
    )

    # --------------------------------------------------------
    # Validate optional advanced capsule sensors
    # --------------------------------------------------------

    mq2 = _validate_optional_number(
        "mq2",
        mq2,
        minimum=0.0,
    )

    mq7 = _validate_optional_number(
        "mq7",
        mq7,
        minimum=0.0,
    )

    infrared_temperature = _validate_optional_number(
        "infrared_temperature",
        infrared_temperature,
    )

    if flame_detected is not None:

        flame_detected = bool(
            flame_detected
        )

    # --------------------------------------------------------
    # Validate optional ERA5 ML features
    # --------------------------------------------------------

    era5_t2m_c = _validate_optional_number(
        "era5_t2m_c",
        era5_t2m_c,
    )

    era5_d2m_c = _validate_optional_number(
        "era5_d2m_c",
        era5_d2m_c,
    )

    era5_wind_speed_ms = _validate_optional_number(
        "era5_wind_speed_ms",
        era5_wind_speed_ms,
        minimum=0.0,
    )

    era5_precip_m = _validate_optional_number(
        "era5_precip_m",
        era5_precip_m,
        minimum=0.0,
    )

    # --------------------------------------------------------
    # Run environmental ML
    # --------------------------------------------------------
    #
    # This is deliberately separate from the capsule sensor
    # intelligence below.
    #
    # The model only runs when all four ERA5 features exist.
    # --------------------------------------------------------

    environmental_ml = _run_environmental_ml(
        era5_t2m_c=era5_t2m_c,
        era5_d2m_c=era5_d2m_c,
        era5_wind_speed_ms=era5_wind_speed_ms,
        era5_precip_m=era5_precip_m,
    )

    # --------------------------------------------------------
    # Sensor availability
    # --------------------------------------------------------

    available_signals: list[str] = []
    unavailable_signals: list[str] = []

    sensor_values = {
        "temperature": temperature,
        "smoke": smoke_level,
        "humidity": humidity,
        "wind": wind_speed,
        "mq2": mq2,
        "mq7": mq7,
        "infrared_temperature": infrared_temperature,
        "flame": flame_detected,
    }

    for name, value in sensor_values.items():

        if value is None:
            unavailable_signals.append(name)

        else:
            available_signals.append(name)

    # --------------------------------------------------------
    # Individual sensor status
    # --------------------------------------------------------

    sensor_status = {
        "temperature": _status(
            temperature,
            TEMPERATURE_ELEVATED,
            TEMPERATURE_CRITICAL,
        ),

        "smoke": _status(
            smoke_level,
            SMOKE_ELEVATED,
            SMOKE_CRITICAL,
        ),

        "mq2": _status(
            mq2,
            MQ2_ELEVATED,
            MQ2_CRITICAL,
        ),

        "mq7": _status(
            mq7,
            MQ7_ELEVATED,
            MQ7_CRITICAL,
        ),

        "infrared_temperature": _status(
            infrared_temperature,
            INFRARED_ELEVATED,
            INFRARED_CRITICAL,
        ),

        "wind": _wind_status(
            wind_speed
        ),

        "humidity": _humidity_status(
            humidity
        ),

        "flame": (
            "DETECTED"
            if flame_detected is True
            else "NOT_DETECTED"
            if flame_detected is False
            else "UNAVAILABLE"
        ),
    }

    # --------------------------------------------------------
    # Fire evidence
    # --------------------------------------------------------

    fire_evidence_score = 0

    critical_conditions = 0
    elevated_conditions = 0

    evidence_signals: list[str] = []

    # Temperature
    if (
        temperature is not None
        and temperature >= TEMPERATURE_CRITICAL
    ):

        critical_conditions += 1
        fire_evidence_score += 20

        evidence_signals.append(
            "critical temperature"
        )

    elif (
        temperature is not None
        and temperature >= TEMPERATURE_ELEVATED
    ):

        elevated_conditions += 1
        fire_evidence_score += 8

        evidence_signals.append(
            "elevated temperature"
        )

    # Smoke
    if (
        smoke_level is not None
        and smoke_level >= SMOKE_CRITICAL
    ):

        critical_conditions += 1
        fire_evidence_score += 25

        evidence_signals.append(
            "critical smoke level"
        )

    elif (
        smoke_level is not None
        and smoke_level >= SMOKE_ELEVATED
    ):

        elevated_conditions += 1
        fire_evidence_score += 10

        evidence_signals.append(
            "elevated smoke level"
        )

    # MQ-2
    if mq2 is not None:

        if mq2 >= MQ2_CRITICAL:

            critical_conditions += 1
            fire_evidence_score += 15

            evidence_signals.append(
                "critical MQ-2 reading"
            )

        elif mq2 >= MQ2_ELEVATED:

            elevated_conditions += 1
            fire_evidence_score += 7

            evidence_signals.append(
                "elevated MQ-2 reading"
            )

    # MQ-7
    if mq7 is not None:

        if mq7 >= MQ7_CRITICAL:

            critical_conditions += 1
            fire_evidence_score += 15

            evidence_signals.append(
                "critical MQ-7 reading"
            )

        elif mq7 >= MQ7_ELEVATED:

            elevated_conditions += 1
            fire_evidence_score += 7

            evidence_signals.append(
                "elevated MQ-7 reading"
            )

    # Infrared temperature
    if infrared_temperature is not None:

        if infrared_temperature >= INFRARED_CRITICAL:

            critical_conditions += 1
            fire_evidence_score += 25

            evidence_signals.append(
                "critical infrared temperature"
            )

        elif infrared_temperature >= INFRARED_ELEVATED:

            elevated_conditions += 1
            fire_evidence_score += 10

            evidence_signals.append(
                "elevated infrared temperature"
            )

    # Flame detection
    #
    # Flame remains strong direct evidence but is kept separate
    # from critical-condition counting.
    #
    if flame_detected is True:

        fire_evidence_score += 35

        evidence_signals.append(
            "flame detected"
        )

    # --------------------------------------------------------
    # Environmental fire-risk intelligence
    # --------------------------------------------------------

    environmental_risk = 0

    environmental_signals: list[str] = []

    if (
        humidity is not None
        and humidity < HUMIDITY_VERY_DRY
    ):

        environmental_risk += 20

        environmental_signals.append(
            "very dry conditions"
        )

    elif (
        humidity is not None
        and humidity < HUMIDITY_DRY
    ):

        environmental_risk += 10

        environmental_signals.append(
            "dry conditions"
        )

    if (
        wind_speed is not None
        and wind_speed >= WIND_HIGH
    ):

        environmental_risk += 20

        environmental_signals.append(
            "strong wind"
        )

    elif (
        wind_speed is not None
        and wind_speed >= WIND_ELEVATED
    ):

        environmental_risk += 10

        environmental_signals.append(
            "elevated wind"
        )

    # --------------------------------------------------------
    # Fire evidence score
    # --------------------------------------------------------

    fire_evidence_score = min(
        100,
        round(
            fire_evidence_score
        ),
    )

    # --------------------------------------------------------
    # Classification
    # --------------------------------------------------------
    #
    # FireGuard uses two evidence sources:
    #
    # 1. Capsule sensor intelligence
    # 2. Real calibrated environmental ML
    #
    # Environmental ML is a screening signal. It can raise a
    # SUSPECTED_FIRE classification, but it cannot by itself
    # declare CONFIRMED_FIRE.
    # --------------------------------------------------------

    ml_fire_probability = (
        environmental_ml[
            "environmental_ml_probability"
        ]
    )

    if (
        flame_detected is True
        and (
            critical_conditions >= 1
            or fire_evidence_score >= 60
        )
    ):

        classification = "CONFIRMED_FIRE"

    elif (
        critical_conditions >= 2
        or fire_evidence_score >= 65
    ):

        classification = "POSSIBLE_FIRE"

    elif (
        critical_conditions >= 1
        and elevated_conditions >= 1
    ):

        classification = "POSSIBLE_FIRE"

    elif (
        elevated_conditions >= 2
    ):

        classification = "SUSPECTED_FIRE"

    elif (
        ml_fire_probability is not None
        and ml_fire_probability >= 0.80
    ):

        classification = "SUSPECTED_FIRE"

    else:

        classification = "NO_FIRE"

    # --------------------------------------------------------
    # Operational severity
    # --------------------------------------------------------

    if classification == "CONFIRMED_FIRE":

        severity = "CRITICAL"

    elif classification == "POSSIBLE_FIRE":

        if fire_evidence_score >= 60:
            severity = "HIGH"

        else:
            severity = "WARNING"

    elif classification == "SUSPECTED_FIRE":

        severity = "WARNING"

    elif environmental_risk >= 30:

        severity = "WARNING"

    else:

        severity = "INFO"

    # --------------------------------------------------------
    # Operational risk
    # --------------------------------------------------------

    risk_score = max(
        fire_evidence_score,
        environmental_risk,
    )

    if classification == "CONFIRMED_FIRE":

        risk_score = max(
            risk_score,
            85,
        )

    elif classification == "POSSIBLE_FIRE":

        risk_score = max(
            risk_score,
            65,
        )

    elif classification == "SUSPECTED_FIRE":

        risk_score = max(
            risk_score,
            40,
        )

    risk_score = min(
        100,
        round(
            risk_score
        ),
    )

    # --------------------------------------------------------
    # Sensor agreement / confidence
    # --------------------------------------------------------
    #
    # This remains sensor agreement.
    # It is NOT statistical ML confidence.
    # --------------------------------------------------------

    fire_signal_names = [
        "temperature",
        "smoke",
        "mq2",
        "mq7",
        "infrared_temperature",
        "flame",
    ]

    available_fire_signals = 0
    abnormal_fire_signals = 0

    for signal_name in fire_signal_names:

        value = sensor_values[
            signal_name
        ]

        if value is None:
            continue

        available_fire_signals += 1

        if signal_name == "temperature":

            if (
                temperature is not None
                and temperature >= TEMPERATURE_ELEVATED
            ):

                abnormal_fire_signals += 1

        elif signal_name == "smoke":

            if (
                smoke_level is not None
                and smoke_level >= SMOKE_ELEVATED
            ):

                abnormal_fire_signals += 1

        elif signal_name == "mq2":

            if (
                mq2 is not None
                and mq2 >= MQ2_ELEVATED
            ):

                abnormal_fire_signals += 1

        elif signal_name == "mq7":

            if (
                mq7 is not None
                and mq7 >= MQ7_ELEVATED
            ):

                abnormal_fire_signals += 1

        elif signal_name == "infrared_temperature":

            if (
                infrared_temperature is not None
                and infrared_temperature >= INFRARED_ELEVATED
            ):

                abnormal_fire_signals += 1

        elif signal_name == "flame":

            if flame_detected is True:

                abnormal_fire_signals += 1

    if available_fire_signals > 0:

        confidence = round(
            (
                abnormal_fire_signals
                / available_fire_signals
            )
            * 100,
            2,
        )

    else:

        confidence = 0.0

    # --------------------------------------------------------
    # Explanation
    # --------------------------------------------------------

    if classification == "CONFIRMED_FIRE":

        explanation = (
            "FireGuard detected strong fire evidence from "
            "the available capsule sensors. Multiple independent "
            "signals support an active fire assessment."
        )

    elif classification == "POSSIBLE_FIRE":

        explanation = (
            "FireGuard detected multiple abnormal sensor "
            "conditions that may indicate a developing fire. "
            "The affected location should be investigated promptly."
        )

    elif classification == "SUSPECTED_FIRE":

        explanation = (
            "FireGuard detected a significant fire-related "
            "environmental or sensor signal. The event requires "
            "continued monitoring and verification."
        )

    elif environmental_risk > 0:

        explanation = (
            "FireGuard does not currently detect sufficient "
            "active-fire evidence, but environmental conditions "
            "increase the potential for fire development or spread."
        )

    else:

        explanation = (
            "The available capsule sensor readings do not "
            "currently provide sufficient evidence of an active fire."
        )

    # --------------------------------------------------------
    # Add environmental ML transparency
    # --------------------------------------------------------

    if (
        environmental_ml[
            "environmental_ml_status"
        ] == "AVAILABLE"
    ):

        calibrated_probability = (
            environmental_ml[
                "environmental_ml_probability"
            ]
        )

        if calibrated_probability is not None:

            explanation += (
                " The calibrated environmental ML model also "
                "produced an environmental fire-risk estimate "
                f"of {calibrated_probability * 100:.1f}% "
                "from the supplied ERA5 conditions."
            )

    elif (
        environmental_ml[
            "environmental_ml_status"
        ] == "UNAVAILABLE"
    ):

        explanation += (
            " Environmental ML was not run because one or more "
            "required ERA5 features were unavailable."
        )

    # --------------------------------------------------------
    # Add unavailable capsule sensor information
    # --------------------------------------------------------

    if unavailable_signals:

        explanation += (
            " The following capsule sensors are currently "
            "unavailable: "
            + ", ".join(
                unavailable_signals
            )
            + "."
        )

    # --------------------------------------------------------
    # Recommended response
    # --------------------------------------------------------

    if severity == "CRITICAL":

        recommended_response = (
            "Initiate emergency fire response and verify "
            "the affected location immediately."
        )

    elif severity == "HIGH":

        recommended_response = (
            "Dispatch verification personnel and prepare "
            "fire-response resources."
        )

    elif severity == "WARNING":

        recommended_response = (
            "Monitor the capsule closely and investigate "
            "the reported conditions."
        )

    else:

        recommended_response = (
            "Continue normal monitoring."
        )

    # --------------------------------------------------------
    # Return complete AI intelligence result
    # --------------------------------------------------------

    return {
        "classification": classification,

        # IMPORTANT:
        # This remains the capsule sensor evidence score.
        # It is NOT the environmental ML probability.
        "fire_probability": float(
            fire_evidence_score
        ),

        # Sensor agreement, not ML confidence.
        "confidence": float(
            confidence
        ),

        "severity": severity,

        "risk_score": int(
            risk_score
        ),

        "flame_detected": flame_detected,

        "sensor_status": sensor_status,

        "critical_conditions": int(
            critical_conditions
        ),

        "elevated_conditions": int(
            elevated_conditions
        ),

        "environmental_risk": int(
            environmental_risk
        ),

        "evidence_signals": evidence_signals,

        "explanation": explanation,

        "recommended_response": recommended_response,

        "model_status": MODEL_STATUS,

        "available_signals": available_signals,

        "unavailable_signals": unavailable_signals,

        "environmental_signals": environmental_signals,

        "fire_evidence_score": int(
            fire_evidence_score
        ),

        # ----------------------------------------------------
        # REAL ENVIRONMENTAL ML OUTPUT
        # ----------------------------------------------------

        "environmental_ml_status": (
            environmental_ml[
                "environmental_ml_status"
            ]
        ),

        "environmental_ml_probability": (
            environmental_ml[
                "environmental_ml_probability"
            ]
        ),

        "environmental_ml_raw_probability": (
            environmental_ml[
                "environmental_ml_raw_probability"
            ]
        ),

        "environmental_ml_features": (
            environmental_ml[
                "environmental_ml_features"
            ]
        ),

        "environmental_ml_unavailable_features": (
            environmental_ml[
                "environmental_ml_unavailable_features"
            ]
        ),

        "environmental_ml_model": (
            environmental_ml[
                "environmental_ml_model"
            ]
        ),
    }