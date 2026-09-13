from datetime import datetime
from typing import Any

from pydantic import BaseModel, EmailStr, Field


# ============================================================
# LOGIN
# ============================================================

class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class LoginResponse(BaseModel):
    message: str
    token: str
    user_id: int
    full_name: str
    email: str


# ============================================================
# REGISTER
# ============================================================

class RegisterRequest(BaseModel):
    full_name: str
    email: EmailStr
    password: str
    phone: str | None = None
    terms_accepted: bool


class RegisterResponse(BaseModel):
    message: str
    user_id: int
    full_name: str
    email: str


# ============================================================
# CAPSULE
# ============================================================

class CapsuleResponse(BaseModel):
    id: int
    capsule_code: str
    name: str

    location_name: str | None = None
    latitude: float | None = None
    longitude: float | None = None

    status: str
    is_active: bool

    battery_level: float | None = None
    solar_status: str | None = None
    communication_status: str | None = None
    sensor_status: str | None = None
    last_communication: datetime | None = None

    owner_id: int

    model_config = {
        "from_attributes": True
    }


# ============================================================
# ALERT TIMELINE EVENT RESPONSE
# ============================================================

class AlertTimelineEventResponse(BaseModel):
    id: int
    event_time: datetime
    description: str
    source: str
    status: str

    model_config = {
        "from_attributes": True
    }


# ============================================================
# ALERT EVIDENCE RESPONSE
# ============================================================

class AlertEvidenceResponse(BaseModel):
    # Basic environmental sensors
    temperature: float | None = None
    smoke_level: float | None = None
    humidity: float | None = None
    wind_speed: float | None = None

    # Advanced FireGuard sensors
    mq2: float | None = None
    mq7: float | None = None
    infrared_temperature: float | None = None
    flame_detected: bool | None = None

    # Device/power information
    battery: float | None = None
    solar_status: str | None = None
    network_status: str | None = None
    device_status: str | None = None

    # GPS information
    gps_lat: float | None = None
    gps_lng: float | None = None

    # AI verification
    ai_confidence: float | None = None
    ai_verification: str | None = None
    fire_classification: str | None = None

    # AI risk intelligence
    ai_risk_score: int | None = None
    ai_severity: str | None = None
    ai_explanation: str | None = None

    # Sensor fusion information
    critical_conditions: int | None = None
    elevated_conditions: int | None = None
    sensor_status_details: dict[str, str] | None = None

    model_config = {
        "from_attributes": True
    }


# ============================================================
# ALERT RESPONSE
# ============================================================

class AlertResponse(BaseModel):
    id: int

    incident_id: int | None = None
    fire_id: str | None = None
    capsule_id: int | None = None

    title: str

    severity: str
    status: str
    alert_type: str

    location: str | None = None

    latitude: float | None = None
    longitude: float | None = None

    detection_time: datetime
    last_updated: datetime

    last_communication: datetime | None = None

    incident_status: str | None = None
    response_status: str | None = None
    suppression_status: str | None = None

    response_activation_time: datetime | None = None

    source_device: str

    evidence: AlertEvidenceResponse

    raw_sensor: dict[str, Any] | None = None

    is_unread: bool

    acknowledged_at: datetime | None = None
    acknowledged_by: int | None = None

    resolved_at: datetime | None = None
    resolved_by: int | None = None

    timeline: list[AlertTimelineEventResponse] = Field(
        default_factory=list
    )

    model_config = {
        "from_attributes": True
    }


# ============================================================
# CAPSULE REGISTER REQUEST
# ============================================================

class CapsuleRegisterRequest(BaseModel):
    capsule_code: str
    name: str

    location_name: str | None = None
    latitude: float | None = None
    longitude: float | None = None


# ============================================================
# CAPSULE REGISTER RESPONSE
# ============================================================

class CapsuleRegisterResponse(BaseModel):
    id: int
    capsule_code: str
    name: str
    device_token: str


# ============================================================
# CAPSULE TELEMETRY RESPONSE
# ============================================================

class CapsuleTelemetryResponse(BaseModel):
    id: int
    capsule_id: int
    recorded_at: datetime

    # GPS
    latitude: float | None = None
    longitude: float | None = None

    # Basic environmental sensors
    temperature: float | None = None
    smoke_level: float | None = None
    humidity: float | None = None
    wind_speed: float | None = None

    # Advanced FireGuard sensors
    mq2: float | None = None
    mq7: float | None = None
    infrared_temperature: float | None = None
    flame_detected: bool | None = None

    # Device status
    battery_level: float | None = None
    solar_status: str | None = None
    communication_status: str | None = None
    sensor_status: str | None = None

    model_config = {
        "from_attributes": True
    }


# ============================================================
# CAPSULE TELEMETRY REQUEST
# ============================================================

class CapsuleTelemetryRequest(BaseModel):
    capsule_code: str
    device_token: str

    recorded_at: datetime | None = None

    # GPS
    latitude: float | None = None
    longitude: float | None = None

    # Basic environmental sensors
    temperature: float | None = None
    smoke_level: float | None = None
    humidity: float | None = None
    wind_speed: float | None = None

    # Advanced FireGuard sensors
    mq2: float | None = None
    mq7: float | None = None
    infrared_temperature: float | None = None
    flame_detected: bool | None = None

    # Device status
    battery_level: float | None = None
    solar_status: str | None = None
    communication_status: str | None = None
    sensor_status: str | None = None


# ============================================================
# AI ALERT ANALYSIS REQUEST
# ============================================================

class AIAlertAnalysisRequest(BaseModel):
    """
    Input data for FireGuard AI sensor-fusion analysis.

    Basic capsule sensor values are optional because a real
    capsule may temporarily have one or more sensors unavailable.

    None means the sensor value is unavailable.
    It must NOT be interpreted as a normal sensor reading.

    Real ERA5 environmental ML features are optional because
    the calibrated environmental machine-learning model can
    only run when all required ERA5 features are available.
    """

    # Basic environmental sensors
    temperature: float | None = None
    smoke_level: float | None = None
    humidity: float | None = None
    wind_speed: float | None = None

    # Advanced FireGuard sensors
    mq2: float | None = None
    mq7: float | None = None
    infrared_temperature: float | None = None
    flame_detected: bool | None = None

    # Real ERA5 environmental ML features
    era5_t2m_c: float | None = None
    era5_d2m_c: float | None = None
    era5_wind_speed_ms: float | None = None
    era5_precip_m: float | None = None


# ============================================================
# AI ALERT ANALYSIS RESPONSE
# ============================================================

class AIAlertAnalysisResponse(BaseModel):
    """
    Result returned by the FireGuard AI sensor-intelligence
    and environmental machine-learning system.

    fire_probability remains the existing API-compatible
    sensor evidence score. It is NOT a calibrated ML probability.

    confidence represents agreement between available
    independent fire-related sensors. It is NOT calibrated
    machine-learning confidence.

    environmental_ml_probability is the calibrated estimate
    produced by the real ERA5 environmental ML model when
    all four ERA5 features are available.
    """

    # --------------------------------------------------------
    # Fire classification
    # --------------------------------------------------------

    classification: str

    # --------------------------------------------------------
    # Fire evidence score
    # --------------------------------------------------------

    fire_probability: float

    fire_evidence_score: int

    # --------------------------------------------------------
    # Sensor agreement
    # --------------------------------------------------------

    confidence: float

    # --------------------------------------------------------
    # Operational severity and risk
    # --------------------------------------------------------

    severity: str
    risk_score: int

    # --------------------------------------------------------
    # Flame sensor
    # --------------------------------------------------------

    flame_detected: bool | None = None

    # --------------------------------------------------------
    # Individual sensor condition states
    # --------------------------------------------------------

    sensor_status: dict[str, str]

    # --------------------------------------------------------
    # Fire-condition counts
    # --------------------------------------------------------

    critical_conditions: int
    elevated_conditions: int

    # --------------------------------------------------------
    # Environmental risk
    # --------------------------------------------------------

    environmental_risk: int

    # --------------------------------------------------------
    # Evidence contributing to assessment
    # --------------------------------------------------------

    evidence_signals: list[str]

    # --------------------------------------------------------
    # Environmental conditions contributing to risk
    # --------------------------------------------------------

    environmental_signals: list[str]

    # --------------------------------------------------------
    # Sensor availability
    # --------------------------------------------------------

    available_signals: list[str]
    unavailable_signals: list[str]

    # --------------------------------------------------------
    # Human-readable AI explanation
    # --------------------------------------------------------

    explanation: str

    # --------------------------------------------------------
    # Recommended operational response
    # --------------------------------------------------------

    recommended_response: str

    # --------------------------------------------------------
    # Intelligence engine identifier
    # --------------------------------------------------------

    model_status: str

    # --------------------------------------------------------
    # Real environmental ML outputs
    # --------------------------------------------------------

    environmental_ml_status: str | None = None
    environmental_ml_raw_probability: float | None = None
    environmental_ml_probability: float | None = None
    environmental_ml_model: str | None = None