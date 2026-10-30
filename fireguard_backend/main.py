from datetime import datetime
import json
import uuid

from fastapi import FastAPI, Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from pydantic import BaseModel

from database import SessionLocal, Base, engine

from models import (
    User,
    FireIncident,
    RiskZone,
    Capsule,
    CapsuleTelemetry,
    Alert,
)

from schemas import (
    LoginRequest,
    LoginResponse,
    RegisterRequest,
    RegisterResponse,
    CapsuleResponse,
    CapsuleRegisterRequest,
    CapsuleRegisterResponse,
    CapsuleTelemetryRequest,
    CapsuleTelemetryResponse,
    AlertResponse,
    AIAlertAnalysisRequest,
    AIAlertAnalysisResponse,
)

from security import (
    verify_password,
    hash_password,
    create_access_token,
    verify_access_token,
)

from device_security import (
    generate_device_token,
    hash_device_token,
    verify_device_token,
)

from ai.predictor import predict_fire
from ai.era5_runtime import lookup_era5
from ai.nasa_fire_intelligence import analyze_nasa_fire_activity
from ai.verification_engine import verify_fire_event


# ============================================================
# AI ASSISTANT REQUEST MODEL
# ============================================================

class AIQueryRequest(BaseModel):
    message: str
    alert_context: dict = {}


# ============================================================
# FASTAPI APPLICATION
# ============================================================

app = FastAPI(
    title="FireGuard API",
    version="1.0.0",
    description=(
        "FireGuard Capsule wildfire detection, "
        "telemetry, alert intelligence and AI API."
    ),
)


# ============================================================
# DATABASE TABLE CREATION
# ============================================================

Base.metadata.create_all(bind=engine)


# ============================================================
# CORS
# ============================================================

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================================
# DATABASE SESSION
# ============================================================

def get_db():
    db = SessionLocal()

    try:
        yield db
    finally:
        db.close()


# ============================================================
# AUTHENTICATED USER
# ============================================================

bearer_scheme = HTTPBearer()


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(
        bearer_scheme
    ),
    db: Session = Depends(get_db),
):
    token = credentials.credentials

    user_id = verify_access_token(token)

    if user_id is None:
        raise HTTPException(
            status_code=401,
            detail="Invalid or expired access token",
        )

    user = (
        db.query(User)
        .filter(User.id == user_id)
        .first()
    )

    if user is None:
        raise HTTPException(
            status_code=401,
            detail="Authenticated user not found",
        )

    return user


# ============================================================
# ROOT
# ============================================================

@app.get("/")
def root():
    return {
        "message": "FireGuard backend is running",
        "service": "FireGuard API",
        "version": "1.0.0",
        "status": "online",
    }


# ============================================================
# HEALTH CHECK
# ============================================================

@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "service": "FireGuard API",
        "timestamp": datetime.utcnow(),
    }


# ============================================================
# LOGIN
# ============================================================

@app.post(
    "/auth/login",
    response_model=LoginResponse,
)
def login(
    request: LoginRequest,
    db: Session = Depends(get_db),
):
    user = (
        db.query(User)
        .filter(User.email == request.email)
        .first()
    )

    if user is None:
        raise HTTPException(
            status_code=401,
            detail="Invalid email or password",
        )

    if not verify_password(
        request.password,
        user.password_hash,
    ):
        raise HTTPException(
            status_code=401,
            detail="Invalid email or password",
        )

    token = create_access_token(user.id)

    return LoginResponse(
        message="Login successful",
        token=token,
        user_id=user.id,
        full_name=user.full_name,
        email=user.email,
    )


# ============================================================
# REGISTER
# ============================================================

@app.post(
    "/auth/register",
    response_model=RegisterResponse,
)
def register(
    request: RegisterRequest,
    db: Session = Depends(get_db),
):
    existing_user = (
        db.query(User)
        .filter(User.email == request.email)
        .first()
    )

    if existing_user is not None:
        raise HTTPException(
            status_code=409,
            detail="Email already exists",
        )

    if not request.terms_accepted:
        raise HTTPException(
            status_code=400,
            detail="Terms & Conditions must be accepted",
        )

    hashed_password = hash_password(
        request.password
    )

    new_user = User(
        full_name=request.full_name,
        email=request.email,
        password_hash=hashed_password,
    )

    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    return RegisterResponse(
        message=(
            "Account created successfully! "
            "Please login."
        ),
        user_id=new_user.id,
        full_name=new_user.full_name,
        email=new_user.email,
    )


# ============================================================
# GIS - ACTIVE FIRES
# ============================================================

@app.get("/api/gis/fires")
def get_active_fires(
    db: Session = Depends(get_db),
):
    fires = (
        db.query(FireIncident)
        .filter(FireIncident.status == "active")
        .all()
    )

    result = []

    for fire in fires:
        detection_time = None

        if fire.detection_time is not None:
            detection_time = (
                fire.detection_time.isoformat()
            )

        latitude = (
            float(fire.latitude)
            if fire.latitude is not None
            else None
        )

        longitude = (
            float(fire.longitude)
            if fire.longitude is not None
            else None
        )

        result.append(
            {
                "id": fire.incident_code,
                "lat": latitude,
                "lng": longitude,
                "severity": fire.severity,
                "title": fire.title,
                "detectionTime": detection_time,
                "status": fire.status,
            }
        )

    return result


# ============================================================
# GIS - FIRE RISK ZONES
# ============================================================

@app.get("/api/gis/risk-zones")
def get_risk_zones(
    db: Session = Depends(get_db),
):
    zones = (
        db.query(RiskZone)
        .all()
    )

    result = []

    for zone in zones:
        try:
            polygon = json.loads(
                zone.polygon_json
            )
        except (
            TypeError,
            json.JSONDecodeError,
        ):
            polygon = []

        risk_score = (
            float(zone.risk_score)
            if zone.risk_score is not None
            else None
        )

        result.append(
            {
                "id": zone.zone_code,
                "riskScore": risk_score,
                "polygon": polygon,
            }
        )

    return result


# ============================================================
# GIS - FIREGUARD CAPSULES
# ============================================================

@app.get(
    "/api/gis/capsules",
    response_model=list[CapsuleResponse],
)
def get_gis_capsules(
    db: Session = Depends(get_db),
):
    capsules = (
        db.query(Capsule)
        .all()
    )

    return capsules


# ============================================================
# CAPSULES
# ============================================================

@app.get(
    "/api/capsules",
    response_model=list[CapsuleResponse],
)
def get_capsules(
    db: Session = Depends(get_db),
):
    capsules = (
        db.query(Capsule)
        .all()
    )

    return capsules


# ============================================================
# CAPSULE DETAIL
# ============================================================

@app.get(
    "/api/capsules/{capsule_id}",
    response_model=CapsuleResponse,
)
def get_capsule_detail(
    capsule_id: int,
    db: Session = Depends(get_db),
):
    capsule = (
        db.query(Capsule)
        .filter(Capsule.id == capsule_id)
        .first()
    )

    if capsule is None:
        raise HTTPException(
            status_code=404,
            detail="Capsule not found",
        )

    return capsule


# ============================================================
# CAPSULE TELEMETRY HISTORY
# ============================================================

@app.get(
    "/api/capsules/{capsule_id}/telemetry",
    response_model=list[CapsuleTelemetryResponse],
)
def get_capsule_telemetry(
    capsule_id: int,
    db: Session = Depends(get_db),
):
    capsule = (
        db.query(Capsule)
        .filter(Capsule.id == capsule_id)
        .first()
    )

    if capsule is None:
        raise HTTPException(
            status_code=404,
            detail="Capsule not found",
        )

    telemetry = (
        db.query(CapsuleTelemetry)
        .filter(
            CapsuleTelemetry.capsule_id
            == capsule_id
        )
        .order_by(
            CapsuleTelemetry.recorded_at.desc()
        )
        .all()
    )

    return telemetry


# ============================================================
# CAPSULE DETAIL - IDENTITY
# ============================================================

@app.get("/capsules/{capsule_id}")
def get_capsule_identity(
    capsule_id: int,
    db: Session = Depends(get_db),
):
    capsule = (
        db.query(Capsule)
        .filter(Capsule.id == capsule_id)
        .first()
    )

    if capsule is None:
        raise HTTPException(
            status_code=404,
            detail="Capsule not found",
        )

    latest_telemetry = (
        db.query(CapsuleTelemetry)
        .filter(
            CapsuleTelemetry.capsule_id
            == capsule_id
        )
        .order_by(
            CapsuleTelemetry.recorded_at.desc()
        )
        .first()
    )

    return {
        "id": capsule.id,
        "capsuleId": str(capsule.id),
        "name": capsule.name,
        "installationLocation": (
            capsule.location_name
        ),
        "operationalState": capsule.status,
        "lastCommunication": (
            capsule.last_communication
        ),
        "lastSensorUpdate": (
            latest_telemetry.recorded_at
            if latest_telemetry is not None
            else None
        ),
    }


# ============================================================
# SENSOR STATE HELPERS
# ============================================================

def temperature_state(value):
    if value is None:
        return "unavailable"

    if value >= 80:
        return "critical"

    if value >= 50:
        return "warning"

    return "normal"


def smoke_state(value):
    if value is None:
        return "unavailable"

    if value >= 70:
        return "critical"

    if value >= 30:
        return "warning"

    return "normal"


def mq2_state(value):
    if value is None:
        return "unavailable"

    if value >= 500:
        return "critical"

    if value >= 200:
        return "warning"

    return "normal"


def mq7_state(value):
    if value is None:
        return "unavailable"

    if value >= 400:
        return "critical"

    if value >= 150:
        return "warning"

    return "normal"


def infrared_temperature_state(value):
    if value is None:
        return "unavailable"

    if value >= 80:
        return "critical"

    if value >= 50:
        return "warning"

    return "normal"


def humidity_state(value):
    if value is None:
        return "unavailable"

    if value < 20:
        return "warning"

    return "normal"


# ============================================================
# CAPSULE DETAIL - LIVE SENSORS
# ============================================================

@app.get("/capsules/{capsule_id}/sensors")
def get_capsule_sensors(
    capsule_id: int,
    db: Session = Depends(get_db),
):
    capsule = (
        db.query(Capsule)
        .filter(Capsule.id == capsule_id)
        .first()
    )

    if capsule is None:
        raise HTTPException(
            status_code=404,
            detail="Capsule not found",
        )

    telemetry = (
        db.query(CapsuleTelemetry)
        .filter(
            CapsuleTelemetry.capsule_id
            == capsule_id
        )
        .order_by(
            CapsuleTelemetry.recorded_at.desc()
        )
        .first()
    )

    if telemetry is None:
        return []

    sensors = []

    if telemetry.temperature is not None:
        sensors.append(
            {
                "sensorId": "temperature",
                "sensorName": "Temperature",
                "value": telemetry.temperature,
                "unit": "°C",
                "displayState": "Available",
                "systemState": temperature_state(
                    telemetry.temperature
                ),
                "timestamp": telemetry.recorded_at,
            }
        )

    if telemetry.smoke_level is not None:
        sensors.append(
            {
                "sensorId": "smoke",
                "sensorName": "Smoke Level",
                "value": telemetry.smoke_level,
                "unit": "",
                "displayState": "Available",
                "systemState": smoke_state(
                    telemetry.smoke_level
                ),
                "timestamp": telemetry.recorded_at,
            }
        )

    if telemetry.humidity is not None:
        sensors.append(
            {
                "sensorId": "humidity",
                "sensorName": "Humidity",
                "value": telemetry.humidity,
                "unit": "%",
                "displayState": "Available",
                "systemState": humidity_state(
                    telemetry.humidity
                ),
                "timestamp": telemetry.recorded_at,
            }
        )

    if telemetry.mq2 is not None:
        sensors.append(
            {
                "sensorId": "mq2",
                "sensorName": "MQ-2 Gas / Smoke",
                "value": telemetry.mq2,
                "unit": "ppm/index",
                "displayState": "Available",
                "systemState": mq2_state(
                    telemetry.mq2
                ),
                "timestamp": telemetry.recorded_at,
            }
        )

    if telemetry.mq7 is not None:
        sensors.append(
            {
                "sensorId": "mq7",
                "sensorName": "MQ-7 Carbon Monoxide",
                "value": telemetry.mq7,
                "unit": "ppm/index",
                "displayState": "Available",
                "systemState": mq7_state(
                    telemetry.mq7
                ),
                "timestamp": telemetry.recorded_at,
            }
        )

    if telemetry.infrared_temperature is not None:
        sensors.append(
            {
                "sensorId": "infrared_temperature",
                "sensorName": "Infrared Temperature",
                "value": telemetry.infrared_temperature,
                "unit": "°C",
                "displayState": "Available",
                "systemState": infrared_temperature_state(
                    telemetry.infrared_temperature
                ),
                "timestamp": telemetry.recorded_at,
            }
        )

    if telemetry.flame_detected is not None:
        sensors.append(
            {
                "sensorId": "flame",
                "sensorName": "Flame Detection",
                "value": (
                    "Detected"
                    if telemetry.flame_detected
                    else "Not detected"
                ),
                "unit": "",
                "displayState": "Available",
                "systemState": (
                    "critical"
                    if telemetry.flame_detected
                    else "normal"
                ),
                "timestamp": telemetry.recorded_at,
            }
        )

    if telemetry.wind_speed is not None:
        sensors.append(
            {
                "sensorId": "wind_speed",
                "sensorName": "Wind Speed",
                "value": telemetry.wind_speed,
                "unit": "m/s",
                "displayState": "Available",
                "systemState": "normal",
                "timestamp": telemetry.recorded_at,
            }
        )

    return sensors


# ============================================================
# CAPSULE REGISTRATION
# ============================================================

@app.post(
    "/api/capsules/register",
    response_model=CapsuleRegisterResponse,
)
def register_capsule(
    request: CapsuleRegisterRequest,
    current_user: User = Depends(
        get_current_user
    ),
    db: Session = Depends(get_db),
):
    existing_capsule = (
        db.query(Capsule)
        .filter(
            Capsule.capsule_code
            == request.capsule_code
        )
        .first()
    )

    if existing_capsule is not None:
        raise HTTPException(
            status_code=409,
            detail="Capsule code already exists",
        )

    device_token = generate_device_token()

    device_token_hash = hash_device_token(
        device_token
    )

    new_capsule = Capsule(
        capsule_code=request.capsule_code,
        name=request.name,
        location_name=request.location_name,
        latitude=request.latitude,
        longitude=request.longitude,
        status="offline",
        is_active=True,
        owner_id=current_user.id,
        device_token_hash=device_token_hash,
    )

    db.add(new_capsule)
    db.commit()
    db.refresh(new_capsule)

    return CapsuleRegisterResponse(
        id=new_capsule.id,
        capsule_code=new_capsule.capsule_code,
        name=new_capsule.name,
        device_token=device_token,
    )


# ============================================================
# RESET DEVICE TOKEN FOR AN OWNED CAPSULE
# ============================================================

@app.post("/api/capsules/{capsule_id}/reset-device-token")
def reset_device_token(
    capsule_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    capsule = (
        db.query(Capsule)
        .filter(
            Capsule.id == capsule_id,
            Capsule.owner_id == current_user.id,
        )
        .first()
    )

    if capsule is None:
        raise HTTPException(
            status_code=404,
            detail="Capsule not found or not owned by you",
        )

    new_token = generate_device_token()
    capsule.device_token_hash = hash_device_token(new_token)

    db.commit()

    return {
        "message": "Device token reset successfully",
        "capsule_id": capsule.id,
        "capsule_code": capsule.capsule_code,
        "device_token": new_token,
    }


# ============================================================
# CAPSULE TELEMETRY INGESTION
# ============================================================

@app.post("/api/device/telemetry")
def receive_capsule_telemetry(
    request: CapsuleTelemetryRequest,
    db: Session = Depends(get_db),
):
    # --------------------------------------------------------
    # 1. FIND CAPSULE
    # --------------------------------------------------------

    capsule = (
        db.query(Capsule)
        .filter(
            Capsule.capsule_code
            == request.capsule_code
        )
        .first()
    )

    if capsule is None:
        raise HTTPException(
            status_code=404,
            detail="Capsule not found",
        )

    # --------------------------------------------------------
    # 2. VERIFY DEVICE TOKEN
    # --------------------------------------------------------

    if not capsule.device_token_hash:
        raise HTTPException(
            status_code=401,
            detail=(
                "Capsule has no registered "
                "device token"
            ),
        )

    token_valid = verify_device_token(
        request.device_token,
        capsule.device_token_hash,
    )

    if not token_valid:
        raise HTTPException(
            status_code=401,
            detail="Invalid device token",
        )

    # --------------------------------------------------------
    # 3. DETERMINE RECORDING TIME
    # --------------------------------------------------------

    recorded_at = (
        request.recorded_at
        if request.recorded_at is not None
        else datetime.utcnow()
    )

    # --------------------------------------------------------
    # 4. CREATE TELEMETRY RECORD
    # --------------------------------------------------------

    telemetry = CapsuleTelemetry(
        capsule_id=capsule.id,
        recorded_at=recorded_at,
        latitude=request.latitude,
        longitude=request.longitude,
        temperature=request.temperature,
        smoke_level=request.smoke_level,
        humidity=request.humidity,
        wind_speed=request.wind_speed,
        mq2=request.mq2,
        mq7=request.mq7,
        infrared_temperature=(
            request.infrared_temperature
        ),
        flame_detected=request.flame_detected,
        battery_level=request.battery_level,
        solar_status=request.solar_status,
        communication_status=(
            request.communication_status
        ),
        sensor_status=request.sensor_status,
    )

    db.add(telemetry)

    # --------------------------------------------------------
    # 5. UPDATE CURRENT CAPSULE STATE
    # --------------------------------------------------------

    if request.latitude is not None:
        capsule.latitude = request.latitude

    if request.longitude is not None:
        capsule.longitude = request.longitude

    if request.battery_level is not None:
        capsule.battery_level = (
            request.battery_level
        )

    if request.solar_status is not None:
        capsule.solar_status = (
            request.solar_status
        )

    if request.communication_status is not None:
        capsule.communication_status = (
            request.communication_status
        )

    if request.sensor_status is not None:
        capsule.sensor_status = request.sensor_status

    # --------------------------------------------------------
    # 6. MARK CAPSULE ONLINE
    # --------------------------------------------------------

    capsule.status = "online"
    capsule.is_active = True
    capsule.last_communication = recorded_at

    # --------------------------------------------------------
    # 7. SAVE TELEMETRY
    # --------------------------------------------------------

    db.commit()
    db.refresh(telemetry)

    # --------------------------------------------------------
    # 8. REAL ERA5 ENVIRONMENTAL LOOKUP
    # --------------------------------------------------------

    era5_result = {
        "status": "UNAVAILABLE",
        "reason": (
            "Capsule GPS or timestamp is unavailable."
        ),
    }

    if (
        telemetry.latitude is not None
        and telemetry.longitude is not None
        and telemetry.recorded_at is not None
    ):
        era5_result = lookup_era5(
            latitude=telemetry.latitude,
            longitude=telemetry.longitude,
            timestamp=telemetry.recorded_at,
        )

    # --------------------------------------------------------
    # 9. REAL FIREGUARD AI
    # --------------------------------------------------------

    ai_result = predict_fire(
        temperature=telemetry.temperature,
        smoke_level=telemetry.smoke_level,
        humidity=telemetry.humidity,
        wind_speed=telemetry.wind_speed,
        mq2=telemetry.mq2,
        mq7=telemetry.mq7,
        infrared_temperature=(
            telemetry.infrared_temperature
        ),
        flame_detected=telemetry.flame_detected,
        era5_t2m_c=era5_result.get(
            "era5_t2m_c"
        ),
        era5_d2m_c=era5_result.get(
            "era5_d2m_c"
        ),
        era5_wind_speed_ms=era5_result.get(
            "era5_wind_speed_ms"
        ),
        era5_precip_m=era5_result.get(
            "era5_precip_m"
        ),
    )

    # --------------------------------------------------------
    # 10. REAL AI -> DATABASE ALERT
    # --------------------------------------------------------

    fire_classification = ai_result.get(
        "classification",
        "NO_FIRE",
    )

    alert_created = False
    alert_id = None

    if fire_classification != "NO_FIRE":

        ml_probability = ai_result.get(
            "environmental_ml_probability"
        )

        ai_confidence = ml_probability

        if ai_confidence is None:
            ai_confidence = ai_result.get(
                "confidence"
            )

        # ----------------------------------------------------
        # GENERATE REQUIRED UNIQUE ALERT CODE
        # ----------------------------------------------------
        #
        # The alerts table requires alert_code to be NOT NULL.
        # Generate a unique production-style identifier for
        # every real FireGuard AI alert.
        #
        # Example:
        # ALT-FG-CAP-001-20260905160000-A1B2C3D4
        #

        alert_code = (
            f"ALT-{capsule.capsule_code}-"
            f"{recorded_at.strftime('%Y%m%d%H%M%S')}-"
            f"{uuid.uuid4().hex[:8].upper()}"
        )

        alert = Alert(
            # REQUIRED ALERT IDENTITY
            alert_code=alert_code,

            capsule_id=capsule.id,

            title=(
                f"FireGuard AI Alert - "
                f"{capsule.capsule_code}"
            ),

            severity=ai_result.get(
                "severity",
                "MEDIUM",
            ),

            status="active",

            alert_type="AI_FIRE_DETECTION",

            location=(
                f"{telemetry.latitude}, "
                f"{telemetry.longitude}"
                if telemetry.latitude is not None
                and telemetry.longitude is not None
                else None
            ),

            latitude=telemetry.latitude,
            longitude=telemetry.longitude,

            detection_time=telemetry.recorded_at,

            last_updated=telemetry.recorded_at,

            last_communication=telemetry.recorded_at,

            response_status="pending",

            suppression_status="not_started",

            source_device=capsule.capsule_code,

            ai_confidence=ai_confidence,

            ai_verification="AI_SCREENED",

            fire_classification=fire_classification,

            raw_sensor=json.dumps(
                {
                    "telemetry": {
                        "temperature": (
                            telemetry.temperature
                        ),
                        "smoke_level": (
                            telemetry.smoke_level
                        ),
                        "humidity": (
                            telemetry.humidity
                        ),
                        "wind_speed": (
                            telemetry.wind_speed
                        ),
                        "mq2": telemetry.mq2,
                        "mq7": telemetry.mq7,
                        "infrared_temperature": (
                            telemetry.infrared_temperature
                        ),
                        "flame_detected": (
                            telemetry.flame_detected
                        ),
                        "battery_level": (
                            telemetry.battery_level
                        ),
                        "solar_status": (
                            telemetry.solar_status
                        ),
                        "communication_status": (
                            telemetry.communication_status
                        ),
                        "sensor_status": (
                            telemetry.sensor_status
                        ),
                        "latitude": (
                            telemetry.latitude
                        ),
                        "longitude": (
                            telemetry.longitude
                        ),
                        "recorded_at": (
                            telemetry.recorded_at.isoformat()
                            if telemetry.recorded_at
                            else None
                        ),
                    },

                    "era5": era5_result,

                    "ai": ai_result,
                },
                default=str,
            ),
        )

        db.add(alert)
        db.commit()
        db.refresh(alert)

        alert_created = True
        alert_id = alert.id

    # --------------------------------------------------------
    # 11. RESPONSE
    # --------------------------------------------------------

    return {
        "message": "Telemetry received successfully",
        "capsule_id": capsule.id,
        "capsule_code": capsule.capsule_code,
        "telemetry_id": telemetry.id,
        "recorded_at": telemetry.recorded_at,
        "status": capsule.status,
        "era5": era5_result,
        "ai": ai_result,
        "alert_created": alert_created,
        "alert_id": alert_id,
    }


# ============================================================
# ALERTS
# ============================================================

@app.get(
    "/api/alerts",
    response_model=list[AlertResponse],
)
def get_alerts(
    db: Session = Depends(get_db),
):
    alerts = (
        db.query(Alert)
        .order_by(
            Alert.detection_time.desc()
        )
        .all()
    )

    result = []

    for alert in alerts:

        # ----------------------------------------------------
        # FIRE / INCIDENT
        # ----------------------------------------------------

        fire_id = None

        if alert.incident is not None:
            fire_id = (
                alert.incident.incident_code
            )

        # ----------------------------------------------------
        # ALERT EVIDENCE
        # ----------------------------------------------------

        evidence = {
            "temperature": alert.temperature,
            "smoke_level": alert.smoke_level,
            "humidity": alert.humidity,
            "wind_speed": alert.wind_speed,
            "mq2": alert.mq2,
            "mq7": alert.mq7,
            "infrared_temperature": (
                alert.infrared_temperature
            ),
            "flame_detected": (
                alert.flame_detected
            ),
            "battery": alert.battery,
            "solar_status": alert.solar_status,
            "network_status": alert.network_status,
            "device_status": alert.device_status,
            "gps_lat": alert.gps_lat,
            "gps_lng": alert.gps_lng,
            "ai_confidence": alert.ai_confidence,
            "ai_verification": alert.ai_verification,
            "fire_classification": (
                alert.fire_classification
            ),
        }

        # ----------------------------------------------------
        # OPTIONAL AI FIELDS
        # ----------------------------------------------------

        if hasattr(alert, "ai_risk_score"):
            evidence["ai_risk_score"] = (
                alert.ai_risk_score
            )

        if hasattr(alert, "ai_severity"):
            evidence["ai_severity"] = (
                alert.ai_severity
            )

        if hasattr(alert, "ai_explanation"):
            evidence["ai_explanation"] = (
                alert.ai_explanation
            )

        if hasattr(alert, "critical_conditions"):
            evidence["critical_conditions"] = (
                alert.critical_conditions
            )

        if hasattr(alert, "elevated_conditions"):
            evidence["elevated_conditions"] = (
                alert.elevated_conditions
            )

        if hasattr(alert, "sensor_status_details"):
            details = (
                alert.sensor_status_details
            )

            if isinstance(details, str):
                try:
                    details = json.loads(details)
                except (
                    TypeError,
                    json.JSONDecodeError,
                ):
                    details = None

            evidence["sensor_status_details"] = details

        # ----------------------------------------------------
        # ALERT TIMELINE
        # ----------------------------------------------------

        timeline = []

        for event in alert.timeline:
            timeline.append(
                {
                    "id": event.id,
                    "event_time": event.event_time,
                    "description": (
                        event.description
                    ),
                    "source": event.source,
                    "status": event.status,
                }
            )

        # ----------------------------------------------------
        # RAW SENSOR DATA
        # ----------------------------------------------------

        raw_sensor = None

        if alert.raw_sensor:
            try:
                raw_sensor = json.loads(
                    alert.raw_sensor
                )
            except (
                TypeError,
                json.JSONDecodeError,
            ):
                raw_sensor = None

        # ----------------------------------------------------
        # NUMERIC ALERT COORDINATES
        # ----------------------------------------------------

        latitude = (
            float(alert.latitude)
            if alert.latitude is not None
            else None
        )

        longitude = (
            float(alert.longitude)
            if alert.longitude is not None
            else None
        )

        gps_lat = (
            float(alert.gps_lat)
            if alert.gps_lat is not None
            else None
        )

        gps_lng = (
            float(alert.gps_lng)
            if alert.gps_lng is not None
            else None
        )

        evidence["gps_lat"] = gps_lat
        evidence["gps_lng"] = gps_lng

        # ----------------------------------------------------
        # RESPONSE OBJECT
        # ----------------------------------------------------

        result.append(
            {
                "id": alert.id,
                "incident_id": alert.incident_id,
                "fire_id": fire_id,
                "capsule_id": alert.capsule_id,
                "title": alert.title,
                "severity": alert.severity,
                "status": alert.status,
                "alert_type": alert.alert_type,
                "location": alert.location,
                "latitude": latitude,
                "longitude": longitude,
                "detection_time": (
                    alert.detection_time
                ),
                "last_updated": (
                    alert.last_updated
                ),
                "last_communication": (
                    alert.last_communication
                ),
                "incident_status": (
                    alert.incident_status
                ),
                "response_status": (
                    alert.response_status
                ),
                "suppression_status": (
                    alert.suppression_status
                ),
                "response_activation_time": (
                    alert.response_activation_time
                ),
                "source_device": (
                    alert.source_device
                ),
                "evidence": evidence,
                "raw_sensor": raw_sensor,
                "timeline": timeline,
                "is_unread": alert.is_unread,
                "acknowledged_at": (
                    alert.acknowledged_at
                ),
                "acknowledged_by": (
                    alert.acknowledged_by
                ),
                "resolved_at": (
                    alert.resolved_at
                ),
                "resolved_by": (
                    alert.resolved_by
                    if hasattr(
                        alert,
                        "resolved_by",
                    )
                    else None
                ),
            }
        )

    return result


# ============================================================
# DASHBOARD SUMMARY
# ============================================================

@app.get("/api/dashboard/summary")
def get_dashboard_summary(
    db: Session = Depends(get_db),
):
    capsules = (
        db.query(Capsule)
        .filter(Capsule.is_active == True)
        .all()
    )

    total_capsules = len(capsules)

    online_capsules = sum(
        1
        for capsule in capsules
        if str(capsule.status).lower()
        == "online"
    )

    offline_capsules = (
        total_capsules - online_capsules
    )

    warning_capsules = 0

    for capsule in capsules:

        battery_warning = (
            capsule.battery_level is not None
            and capsule.battery_level < 30
        )

        communication_warning = (
            capsule.communication_status
            is not None
            and str(
                capsule.communication_status
            ).lower()
            not in [
                "online",
                "connected",
                "ok",
                "healthy",
            ]
        )

        sensor_warning = (
            capsule.sensor_status is not None
            and str(
                capsule.sensor_status
            ).lower()
            not in [
                "online",
                "ok",
                "healthy",
                "normal",
            ]
        )

        if (
            battery_warning
            or communication_warning
            or sensor_warning
        ):
            warning_capsules += 1

    active_incidents = (
        db.query(FireIncident)
        .filter(
            FireIncident.status == "active"
        )
        .count()
    )

    available_response_units = online_capsules

    active_response_units = (
        db.query(Alert)
        .filter(
            Alert.status == "active",
            Alert.response_status.isnot(None),
        )
        .count()
    )

    if total_capsules > 0:
        readiness_percentage = (
            online_capsules
            / total_capsules
            * 100
        )
    else:
        readiness_percentage = 0.0

    if total_capsules == 0:
        system_health = "NO CAPSULES"

    elif online_capsules == total_capsules:
        system_health = "HEALTHY"

    elif online_capsules > 0:
        system_health = "DEGRADED"

    else:
        system_health = "OFFLINE"

    risk_zones = (
        db.query(RiskZone)
        .all()
    )

    risk_values = [
        float(zone.risk_score)
        for zone in risk_zones
        if zone.risk_score is not None
    ]

    if not risk_values:
        fire_risk = "UNKNOWN"

    else:
        max_risk = max(risk_values)

        if max_risk >= 0.75:
            fire_risk = "CRITICAL"

        elif max_risk >= 0.50:
            fire_risk = "HIGH"

        elif max_risk >= 0.25:
            fire_risk = "MODERATE"

        else:
            fire_risk = "LOW"

    return {
        "activeIncidents": active_incidents,
        "totalCapsules": total_capsules,
        "onlineCapsules": online_capsules,
        "offlineCapsules": offline_capsules,
        "warningCapsules": warning_capsules,
        "readinessPercentage": (
            readiness_percentage
        ),
        "availableResponseUnits": (
            available_response_units
        ),
        "activeResponseUnits": (
            active_response_units
        ),
        "systemHealth": system_health,
        "fireRisk": fire_risk,
    }


# ============================================================
# SYSTEM HEALTH
# ============================================================

@app.get("/api/system/health")
def get_system_health(
    db: Session = Depends(get_db),
):
    capsules = (
        db.query(Capsule)
        .filter(Capsule.is_active == True)
        .all()
    )

    total_capsules = len(capsules)

    online_capsules = sum(
        1
        for capsule in capsules
        if str(capsule.status).lower()
        == "online"
    )

    offline_capsules = (
        total_capsules - online_capsules
    )

    healthy_capsules = 0

    for capsule in capsules:

        communication_ok = (
            capsule.communication_status is None
            or str(
                capsule.communication_status
            ).lower()
            in [
                "online",
                "connected",
                "ok",
                "healthy",
            ]
        )

        sensor_ok = (
            capsule.sensor_status is None
            or str(
                capsule.sensor_status
            ).lower()
            in [
                "online",
                "ok",
                "healthy",
                "normal",
            ]
        )

        battery_ok = (
            capsule.battery_level is None
            or capsule.battery_level >= 30
        )

        capsule_online = (
            str(capsule.status).lower()
            == "online"
        )

        if (
            capsule_online
            and communication_ok
            and sensor_ok
            and battery_ok
        ):
            healthy_capsules += 1

    if total_capsules == 0:
        overall_status = "NO CAPSULES"

    elif healthy_capsules == total_capsules:
        overall_status = "HEALTHY"

    elif healthy_capsules > 0:
        overall_status = "DEGRADED"

    else:
        overall_status = "OFFLINE"

    return {
        "status": overall_status,
        "totalCapsules": total_capsules,
        "onlineCapsules": online_capsules,
        "offlineCapsules": offline_capsules,
        "healthyCapsules": healthy_capsules,
    }


# ============================================================
# AI ALERT ANALYSIS
# ============================================================

@app.post(
    "/api/ai/analyze-alert",
    response_model=AIAlertAnalysisResponse,
)
def analyze_alert(
    request: AIAlertAnalysisRequest,
):
    result = predict_fire(
        temperature=request.temperature,
        smoke_level=request.smoke_level,
        humidity=request.humidity,
        wind_speed=request.wind_speed,
        mq2=request.mq2,
        mq7=request.mq7,
        infrared_temperature=(
            request.infrared_temperature
        ),
        flame_detected=request.flame_detected,
        era5_t2m_c=request.era5_t2m_c,
        era5_d2m_c=request.era5_d2m_c,
        era5_wind_speed_ms=request.era5_wind_speed_ms,
        era5_precip_m=request.era5_precip_m,
    )

    return result


# ============================================================
# NASA FIRMS FIRE INTELLIGENCE
# ============================================================

@app.get("/api/nasa/fire-intelligence")
def nasa_fire_intelligence(
    latitude: float,
    longitude: float,
    radius_km: float = 25.0,
):
    """
    Analyze real NASA FIRMS satellite fire detections
    around a geographic location.

    This endpoint provides satellite fire evidence.
    It does NOT replace the FireGuard capsule AI model.
    """

    return analyze_nasa_fire_activity(
        latitude=latitude,
        longitude=longitude,
        radius_km=radius_km,
    )


# ============================================================
# FIRE VERIFICATION
# ============================================================

@app.post("/api/ai/verify-fire")
def verify_fire(
    ai_analysis: dict,
    nasa_evidence: dict,
):
    """
    Combine FireGuard AI sensor analysis with
    NASA FIRMS satellite evidence.
    """

    return verify_fire_event(
        ai_analysis=ai_analysis,
        nasa_evidence=nasa_evidence,
    )


# ============================================================
# AI ASSISTANT
# ============================================================

@app.post("/api/ai/assistant")
def ai_assistant(
    request: AIQueryRequest,
):
    """
    FireGuard domain AI assistant.

    This assistant does not invent sensor readings.
    It uses the real alert context supplied by Flutter,
    the existing FireGuard fire model, and NASA FIRMS
    evidence when real coordinates are available.
    """

    message = request.message.strip()
    context = request.alert_context or {}

    if not message:
        return {
            "response": "Please provide a question.",
            "classification": "NO_QUERY",
            "severity": "UNKNOWN",
            "explanation": "No question was provided.",
            "recommended_action": "Ask a FireGuard question.",
            "evidence": {},
        }

    message_lower = message.lower()

    # --------------------------------------------------------
    # HELPERS
    # --------------------------------------------------------

    def get_value(*keys):
        for key in keys:
            value = context.get(key)

            if value is not None:
                return value

        return None

    def format_value(value, unit=""):
        if value is None:
            return "unavailable"

        return f"{value}{unit}"

    def severity_from_classification(classification):
        if classification is None:
            return "UNKNOWN"

        value = str(classification).upper()

        if "CRITICAL" in value:
            return "CRITICAL"

        if "HIGH" in value:
            return "HIGH"

        if "MEDIUM" in value:
            return "MEDIUM"

        if "LOW" in value:
            return "LOW"

        if "NO_FIRE" in value:
            return "LOW"

        return "UNKNOWN"

    # --------------------------------------------------------
    # CURRENT ALERT CONTEXT
    # --------------------------------------------------------

    alert_id = get_value(
        "alertId",
        "alert_id",
    )

    incident_id = get_value(
        "incidentId",
        "incident_id",
    )

    fire_id = get_value(
        "fireId",
        "fire_id",
    )

    capsule_id = get_value(
        "capsuleId",
        "capsule_id",
    )

    title = get_value("title")

    current_severity = get_value(
        "severity"
    )

    current_status = get_value(
        "status"
    )

    alert_type = get_value(
        "alertType",
        "alert_type",
    )

    location = get_value(
        "location"
    )

    latitude = get_value(
        "latitude"
    )

    longitude = get_value(
        "longitude"
    )

    # --------------------------------------------------------
    # REAL SENSOR VALUES
    # --------------------------------------------------------

    temperature = get_value(
        "temperature"
    )

    smoke_level = get_value(
        "smokeLevel",
        "smoke_level",
    )

    humidity = get_value(
        "humidity"
    )

    wind_speed = get_value(
        "windSpeed",
        "wind_speed",
    )

    mq2 = get_value("mq2")

    mq7 = get_value("mq7")

    infrared_temperature = get_value(
        "infraredTemperature",
        "infrared_temperature",
    )

    flame_detected = get_value(
        "flameDetected",
        "flame_detected",
    )

    battery = get_value(
        "battery",
        "batteryLevel",
        "battery_level",
    )

    ai_confidence = get_value(
        "aiConfidence",
        "ai_confidence",
    )

    ai_verification = get_value(
        "aiVerification",
        "ai_verification",
    )

    fire_classification = get_value(
        "fireClassification",
        "fire_classification",
    )

    # --------------------------------------------------------
    # ENVIRONMENTAL ML VALUES
    #
    # Only use these when ACTUAL ERA5 values are supplied.
    # Never estimate or fabricate them.
    # --------------------------------------------------------

    era5_t2m_c = get_value(
        "era5_t2m_c",
        "era5T2mC",
    )

    era5_d2m_c = get_value(
        "era5_d2m_c",
        "era5D2mC",
    )

    era5_wind_speed_ms = get_value(
        "era5_wind_speed_ms",
        "era5WindSpeedMs",
    )

    era5_precip_m = get_value(
        "era5_precip_m",
        "era5PrecipM",
    )

    # --------------------------------------------------------
    # RUN FIREGUARD AI WHEN ENOUGH REAL SENSOR DATA EXISTS
    # --------------------------------------------------------

    ai_result = None

    has_sensor_data = any(
        value is not None
        for value in [
            temperature,
            smoke_level,
            humidity,
            wind_speed,
            mq2,
            mq7,
            infrared_temperature,
            flame_detected,
        ]
    )

    if has_sensor_data:
        try:
            ai_result = predict_fire(
                temperature=temperature,
                smoke_level=smoke_level,
                humidity=humidity,
                wind_speed=wind_speed,
                mq2=mq2,
                mq7=mq7,
                infrared_temperature=(
                    infrared_temperature
                ),
                flame_detected=flame_detected,
                era5_t2m_c=era5_t2m_c,
                era5_d2m_c=era5_d2m_c,
                era5_wind_speed_ms=(
                    era5_wind_speed_ms
                ),
                era5_precip_m=era5_precip_m,
            )

        except Exception:
            ai_result = None

    # --------------------------------------------------------
    # INTENT: CURRENT ALERT / STATUS
    # --------------------------------------------------------

    asks_about_status = any(
        word in message_lower
        for word in [
            "status",
            "what is happening",
            "what's happening",
            "current alert",
            "current situation",
            "situation",
        ]
    )

    if asks_about_status:

        if alert_id is None:
            response = (
                "There is no selected FireGuard alert "
                "available in my current context."
            )

            return {
                "response": response,
                "classification": (
                    fire_classification
                    or "NO_ACTIVE_ALERT_CONTEXT"
                ),
                "severity": (
                    current_severity
                    or "UNKNOWN"
                ),
                "explanation": (
                    "The assistant does not have "
                    "a selected alert to describe."
                ),
                "recommended_action": (
                    "Select a FireGuard alert "
                    "and ask again."
                ),
                "evidence": {},
            }

        response_parts = []

        response_parts.append(
            f"The current FireGuard alert is "
            f"{title or 'an active alert'}."
        )

        if current_severity is not None:
            response_parts.append(
                f"Severity is {current_severity}."
            )

        if current_status is not None:
            response_parts.append(
                f"Status is {current_status}."
            )

        if capsule_id is not None:
            response_parts.append(
                f"It was reported by capsule "
                f"{capsule_id}."
            )

        if location is not None:
            response_parts.append(
                f"The recorded location is "
                f"{location}."
            )

        response = " ".join(response_parts)

        return {
            "response": response,
            "classification": (
                fire_classification
                or "ALERT"
            ),
            "severity": (
                current_severity
                or severity_from_classification(
                    fire_classification
                )
            ),
            "explanation": (
                "This assessment is based on "
                "the current FireGuard alert context."
            ),
            "recommended_action": (
                "Review the alert evidence and "
                "follow the operational response procedure."
            ),
            "evidence": {
                "alert_id": alert_id,
                "incident_id": incident_id,
                "fire_id": fire_id,
                "capsule_id": capsule_id,
                "status": current_status,
                "location": location,
            },
        }

    # --------------------------------------------------------
    # INTENT: SENSOR QUESTIONS
    # --------------------------------------------------------

    asks_about_sensors = any(
        word in message_lower
        for word in [
            "sensor",
            "temperature",
            "smoke",
            "humidity",
            "wind",
            "gas",
            "carbon monoxide",
            "mq2",
            "mq7",
            "flame",
            "infrared",
            "battery",
        ]
    )

    if asks_about_sensors:

        sensor_lines = []

        if temperature is not None:
            sensor_lines.append(
                f"temperature is "
                f"{format_value(temperature, ' °C')}"
            )

        if smoke_level is not None:
            sensor_lines.append(
                f"smoke level is "
                f"{format_value(smoke_level)}"
            )

        if humidity is not None:
            sensor_lines.append(
                f"humidity is "
                f"{format_value(humidity, ' %')}"
            )

        if wind_speed is not None:
            sensor_lines.append(
                f"wind speed is "
                f"{format_value(wind_speed, ' m/s')}"
            )

        if mq2 is not None:
            sensor_lines.append(
                f"MQ-2 is "
                f"{format_value(mq2)}"
            )

        if mq7 is not None:
            sensor_lines.append(
                f"MQ-7 is "
                f"{format_value(mq7)}"
            )

        if infrared_temperature is not None:
            sensor_lines.append(
                f"infrared temperature is "
                f"{format_value(\
                    infrared_temperature,\
                    ' °C'\
                )}"
            )

        if flame_detected is not None:
            sensor_lines.append(
                "flame detection is "
                + (
                    "active"
                    if flame_detected
                    else "not detected"
                )
            )

        if battery is not None:
            sensor_lines.append(
                f"battery is "
                f"{format_value(battery, ' %')}"
            )

        if not sensor_lines:
            response = (
                "No current sensor measurements "
                "are available in the selected "
                "FireGuard context."
            )

        else:
            response = (
                "The available FireGuard sensor "
                "readings are: "
                + "; ".join(sensor_lines)
                + "."
            )

        return {
            "response": response,
            "classification": (
                fire_classification
                or "SENSOR_STATUS"
            ),
            "severity": (
                current_severity
                or "UNKNOWN"
            ),
            "explanation": (
                "Only sensor values actually "
                "provided by FireGuard are reported."
            ),
            "recommended_action": (
                "Use the FireGuard AI assessment "
                "together with the sensor evidence "
                "when evaluating an alert."
            ),
            "evidence": {
                "temperature": temperature,
                "smoke_level": smoke_level,
                "humidity": humidity,
                "wind_speed": wind_speed,
                "mq2": mq2,
                "mq7": mq7,
                "infrared_temperature": (
                    infrared_temperature
                ),
                "flame_detected": flame_detected,
                "battery": battery,
            },
        }

    # --------------------------------------------------------
    # INTENT: FIRE RISK / AI ANALYSIS
    # --------------------------------------------------------

    asks_about_risk = any(
        word in message_lower
        for word in [
            "risk",
            "danger",
            "fire",
            "fire risk",
            "likely",
            "probability",
            "confidence",
            "ai",
            "analysis",
            "prediction",
            "predict",
        ]
    )

    if asks_about_risk:

        if ai_result is not None:

            classification = ai_result.get(
                "classification",
                fire_classification
                or "UNKNOWN",
            )

            severity = ai_result.get(
                "severity",
                current_severity
                or "UNKNOWN",
            )

            confidence = ai_result.get(
                "confidence"
            )

            environmental_probability = (
                ai_result.get(
                    "environmental_ml_probability"
                )
            )

            explanation = ai_result.get(
                "explanation"
            )

            if classification == "NO_FIRE":
                response = (
                    "The current FireGuard sensor "
                    "analysis does not classify the "
                    "observed conditions as a fire."
                )

            else:
                response = (
                    "The current FireGuard AI analysis "
                    f"classifies the conditions as "
                    f"{classification} with "
                    f"{severity} severity."
                )

            if confidence is not None:
                response += (
                    f" The sensor-model confidence "
                    f"is {confidence:.1%}."
                )

            if environmental_probability is not None:
                response += (
                    f" The calibrated environmental "
                    f"model output is "
                    f"{environmental_probability:.1%}."
                )

            if explanation:
                response += (
                    f" {explanation}"
                )

            return {
                "response": response,
                "classification": classification,
                "severity": severity,
                "explanation": (
                    explanation
                    or "Assessment generated by "
                    "the existing FireGuard fire model."
                ),
                "recommended_action": (
                    "Continue monitoring the alert "
                    "and follow the appropriate "
                    "FireGuard response procedure."
                ),
                "evidence": {
                    "ai": ai_result,
                    "environmental_ml_available": (
                        all(
                            value is not None
                            for value in [
                                era5_t2m_c,
                                era5_d2m_c,
                                era5_wind_speed_ms,
                                era5_precip_m,
                            ]
                        )
                    ),
                },
            }

        response = (
            "I cannot produce a new FireGuard fire "
            "assessment from the current context because "
            "there are not enough real sensor measurements."
        )

        return {
            "response": response,
            "classification": (
                fire_classification
                or "INSUFFICIENT_DATA"
            ),
            "severity": (
                current_severity
                or "UNKNOWN"
            ),
            "explanation": (
                "FireGuard does not fabricate missing "
                "sensor or environmental measurements."
            ),
            "recommended_action": (
                "Wait for real capsule telemetry "
                "or select an alert containing sensor evidence."
            ),
            "evidence": {
                "sensor_data_available": has_sensor_data,
            },
        }

    # --------------------------------------------------------
    # INTENT: NASA SATELLITE EVIDENCE
    # --------------------------------------------------------

    asks_about_nasa = any(
        word in message_lower
        for word in [
            "nasa",
            "satellite",
            "satellite fire",
            "firms",
            "remote sensing",
        ]
    )

    if asks_about_nasa:

        if (
            latitude is None
            or longitude is None
        ):
            return {
                "response": (
                    "NASA FIRMS satellite evidence "
                    "cannot be checked for this alert "
                    "because valid coordinates are "
                    "not available."
                ),
                "classification": (
                    fire_classification
                    or "NASA_EVIDENCE_UNAVAILABLE"
                ),
                "severity": (
                    current_severity
                    or "UNKNOWN"
                ),
                "explanation": (
                    "A geographic location is required "
                    "to query the FireGuard NASA "
                    "fire-intelligence service."
                ),
                "recommended_action": (
                    "Use an alert with valid GPS coordinates."
                ),
                "evidence": {
                    "latitude": latitude,
                    "longitude": longitude,
                },
            }

        try:
            nasa_result = analyze_nasa_fire_activity(
                latitude=float(latitude),
                longitude=float(longitude),
                radius_km=25.0,
            )

            return {
                "response": (
                    "I checked the available NASA FIRMS "
                    "satellite fire evidence around the "
                    "FireGuard alert location."
                ),
                "classification": (
                    fire_classification
                    or "NASA_EVIDENCE_CHECKED"
                ),
                "severity": (
                    current_severity
                    or "UNKNOWN"
                ),
                "explanation": (
                    "NASA FIRMS provides satellite "
                    "fire-detection evidence and is "
                    "used as supporting evidence rather "
                    "than as a replacement for capsule AI."
                ),
                "recommended_action": (
                    "Compare satellite evidence with "
                    "FireGuard sensor and AI evidence "
                    "before making an operational decision."
                ),
                "evidence": {
                    "latitude": latitude,
                    "longitude": longitude,
                    "nasa": nasa_result,
                },
            }

        except Exception as exc:
            return {
                "response": (
                    "The FireGuard NASA satellite "
                    "evidence service could not be "
                    "queried at this time."
                ),
                "classification": (
                    "NASA_EVIDENCE_UNAVAILABLE"
                ),
                "severity": (
                    current_severity
                    or "UNKNOWN"
                ),
                "explanation": (
                    "The satellite evidence service "
                    "returned an error."
                ),
                "recommended_action": (
                    "Continue using the available "
                    "FireGuard sensor and AI evidence."
                ),
                "evidence": {},
            }

    # --------------------------------------------------------
    # INTENT: LOCATION
    # --------------------------------------------------------

    asks_about_location = any(
        word in message_lower
        for word in [
            "where",
            "location",
            "located",
            "coordinates",
            "gps",
        ]
    )

    if asks_about_location:

        if (
            latitude is None
            and longitude is None
            and location is None
        ):
            response = (
                "The current FireGuard context does "
                "not contain a valid alert location."
            )

        elif location is not None:
            response = (
                f"The FireGuard alert location is "
                f"{location}."
            )

        else:
            response = (
                "The FireGuard GPS coordinates are "
                f"latitude {latitude} and "
                f"longitude {longitude}."
            )

        return {
            "response": response,
            "classification": (
                fire_classification
                or "LOCATION"
            ),
            "severity": (
                current_severity
                or "UNKNOWN"
            ),
            "explanation": (
                "The location comes from the "
                "available FireGuard alert context."
            ),
            "recommended_action": (
                "Use the mapped FireGuard location "
                "for incident assessment."
            ),
            "evidence": {
                "location": location,
                "latitude": latitude,
                "longitude": longitude,
            },
        }

    # --------------------------------------------------------
    # DEFAULT FIREGUARD RESPONSE
    # --------------------------------------------------------

    response = (
        "I am the FireGuard AI assistant. "
        "I can help you understand the current "
        "fire alert, sensor readings, AI assessment, "
        "GPS location, NASA satellite evidence, "
        "and recommended response actions."
    )

    if title is not None:
        response += (
            f" The selected alert is "
            f"{title}."
        )

    return {
        "response": response,
        "classification": (
            fire_classification
            or "FIREGUARD_ASSISTANT"
        ),
        "severity": (
            current_severity
            or "UNKNOWN"
        ),
        "explanation": (
            "The assistant uses the FireGuard "
            "alert context and existing intelligence "
            "services."
        ),
        "recommended_action": (
            "Ask about the alert, sensors, fire risk, "
            "location, AI analysis, or NASA evidence."
        ),
        "evidence": {
            "alert_id": alert_id,
            "capsule_id": capsule_id,
        },
    }