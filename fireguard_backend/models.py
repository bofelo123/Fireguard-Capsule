from sqlalchemy import (
    Column,
    Integer,
    String,
    Float,
    Boolean,
    DateTime,
    ForeignKey,
    Text,
)
from sqlalchemy.orm import relationship

from database import Base

# ============================================================
# USERS
# ============================================================

class User(Base):
    __tablename__ = "users"

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    full_name = Column(
        String,
        nullable=False,
    )

    email = Column(
        String,
        unique=True,
        nullable=False,
        index=True,
    )

    password_hash = Column(
        String,
        nullable=False,
    )

    capsules = relationship(
        "Capsule",
        back_populates="owner",
    )

# ============================================================
# CAPSULES
# ============================================================

class Capsule(Base):
    __tablename__ = "capsules"

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    capsule_code = Column(
        String,
        unique=True,
        nullable=False,
        index=True,
    )

    name = Column(
        String,
        nullable=False,
    )

    device_token_hash = Column(
        String,
        nullable=True,
        unique=True,
        index=True,
    )

    location_name = Column(
        String,
        nullable=True,
    )

    latitude = Column(
        Float,
        nullable=True,
    )

    longitude = Column(
        Float,
        nullable=True,
    )

    status = Column(
        String,
        nullable=False,
        default="offline",
    )

    is_active = Column(
        Boolean,
        nullable=False,
        default=True,
    )

    battery_level = Column(
        Float,
        nullable=True,
    )

    solar_status = Column(
        String,
        nullable=True,
    )

    communication_status = Column(
        String,
        nullable=True,
    )

    sensor_status = Column(
        String,
        nullable=True,
    )

    last_communication = Column(
        DateTime,
        nullable=True,
    )

    owner_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=False,
    )

    owner = relationship(
        "User",
        back_populates="capsules",
    )

# ============================================================
# FIRE INCIDENTS
# ============================================================

class FireIncident(Base):
    __tablename__ = "fire_incidents"

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    incident_code = Column(
        String,
        unique=True,
        nullable=False,
        index=True,
    )

    title = Column(
        String,
        nullable=False,
    )

    latitude = Column(
        Float,
        nullable=False,
    )

    longitude = Column(
        Float,
        nullable=False,
    )

    severity = Column(
        String,
        nullable=False,
        default="info",
    )

    status = Column(
        String,
        nullable=False,
        default="active",
    )

    detection_time = Column(
        DateTime,
        nullable=False,
    )

# ============================================================
# RISK ZONES
# ============================================================

class RiskZone(Base):
    __tablename__ = "risk_zones"

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    zone_code = Column(
        String,
        unique=True,
        nullable=False,
        index=True,
    )

    risk_score = Column(
        Float,
        nullable=False,
    )

    polygon_json = Column(
        String,
        nullable=False,
    )

# ============================================================
# ALERTS
# ============================================================

class Alert(Base):
    __tablename__ = "alerts"

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    alert_code = Column(
        String,
        unique=True,
        nullable=False,
        index=True,
    )

    incident_id = Column(
        Integer,
        ForeignKey("fire_incidents.id"),
        nullable=True,
        index=True,
    )

    capsule_id = Column(
        Integer,
        ForeignKey("capsules.id"),
        nullable=True,
        index=True,
    )

    title = Column(
        String,
        nullable=False,
    )

    severity = Column(
        String,
        nullable=False,
        default="info",
    )

    status = Column(
        String,
        nullable=False,
        default="active",
    )

    alert_type = Column(
        String,
        nullable=False,
    )

    location = Column(
        String,
        nullable=True,
    )

    latitude = Column(
        Float,
        nullable=True,
    )

    longitude = Column(
        Float,
        nullable=True,
    )

    detection_time = Column(
        DateTime,
        nullable=False,
    )

    last_updated = Column(
        DateTime,
        nullable=False,
    )

    last_communication = Column(
        DateTime,
        nullable=True,
    )

    incident_status = Column(
        String,
        nullable=True,
    )

    response_status = Column(
        String,
        nullable=True,
    )

    suppression_status = Column(
        String,
        nullable=True,
    )

    response_activation_time = Column(
        DateTime,
        nullable=True,
    )

    source_device = Column(
        String,
        nullable=False,
    )

    # --------------------------------------------------------
    # Basic environmental sensor data
    # --------------------------------------------------------

    temperature = Column(
        Float,
        nullable=True,
    )

    smoke_level = Column(
        Float,
        nullable=True,
    )

    humidity = Column(
        Float,
        nullable=True,
    )

    wind_speed = Column(
        Float,
        nullable=True,
    )

    # --------------------------------------------------------
    # Advanced FireGuard sensor data
    # --------------------------------------------------------

    mq2 = Column(
        Float,
        nullable=True,
    )

    mq7 = Column(
        Float,
        nullable=True,
    )

    infrared_temperature = Column(
        Float,
        nullable=True,
    )

    flame_detected = Column(
        Boolean,
        nullable=True,
    )

    # --------------------------------------------------------
    # Device / power status
    # --------------------------------------------------------

    battery = Column(
        Float,
        nullable=True,
    )

    solar_status = Column(
        String,
        nullable=True,
    )

    network_status = Column(
        String,
        nullable=True,
    )

    device_status = Column(
        String,
        nullable=True,
    )

    # --------------------------------------------------------
    # GPS
    # --------------------------------------------------------

    gps_lat = Column(
        Float,
        nullable=True,
    )

    gps_lng = Column(
        Float,
        nullable=True,
    )

    # --------------------------------------------------------
    # AI verification
    # --------------------------------------------------------

    ai_confidence = Column(
        Float,
        nullable=True,
    )

    ai_verification = Column(
        String,
        nullable=True,
    )

    fire_classification = Column(
        String,
        nullable=True,
    )

    # --------------------------------------------------------
    # Raw sensor payload
    # --------------------------------------------------------

    raw_sensor = Column(
        Text,
        nullable=True,
    )

    is_unread = Column(
        Boolean,
        nullable=False,
        default=True,
    )

    acknowledged_at = Column(
        DateTime,
        nullable=True,
    )

    acknowledged_by = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=True,
    )

    resolved_at = Column(
        DateTime,
        nullable=True,
    )

    resolved_by = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=True,
    )

    incident = relationship(
        "FireIncident",
    )

    capsule = relationship(
        "Capsule",
    )

    acknowledged_user = relationship(
        "User",
        foreign_keys=[acknowledged_by],
    )

    resolved_user = relationship(
        "User",
        foreign_keys=[resolved_by],
    )

    timeline = relationship(
        "AlertTimelineEvent",
        back_populates="alert",
        cascade="all, delete-orphan",
        order_by="AlertTimelineEvent.event_time",
    )

# ============================================================
# ALERT TIMELINE
# ============================================================

class AlertTimelineEvent(Base):
    __tablename__ = "alert_timeline_events"

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    alert_id = Column(
        Integer,
        ForeignKey("alerts.id"),
        nullable=False,
        index=True,
    )

    event_time = Column(
        DateTime,
        nullable=False,
    )

    description = Column(
        String,
        nullable=False,
    )

    source = Column(
        String,
        nullable=False,
    )

    status = Column(
        String,
        nullable=False,
    )

    alert = relationship(
        "Alert",
        back_populates="timeline",
    )

# ============================================================
# CAPSULE TELEMETRY
# ============================================================

class CapsuleTelemetry(Base):
    __tablename__ = "capsule_telemetry"

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    capsule_id = Column(
        Integer,
        ForeignKey("capsules.id"),
        nullable=False,
        index=True,
    )

    recorded_at = Column(
        DateTime,
        nullable=False,
        index=True,
    )

    # --------------------------------------------------------
    # GPS
    # --------------------------------------------------------

    latitude = Column(
        Float,
        nullable=True,
    )

    longitude = Column(
        Float,
        nullable=True,
    )

    # --------------------------------------------------------
    # Basic environmental sensors
    # --------------------------------------------------------

    temperature = Column(
        Float,
        nullable=True,
    )

    smoke_level = Column(
        Float,
        nullable=True,
    )

    humidity = Column(
        Float,
        nullable=True,
    )

    wind_speed = Column(
        Float,
        nullable=True,
    )

    # --------------------------------------------------------
    # Advanced FireGuard sensors
    # --------------------------------------------------------

    mq2 = Column(
        Float,
        nullable=True,
    )

    mq7 = Column(
        Float,
        nullable=True,
    )

    infrared_temperature = Column(
        Float,
        nullable=True,
    )

    flame_detected = Column(
        Boolean,
        nullable=True,
    )

    # --------------------------------------------------------
    # Device status
    # --------------------------------------------------------

    battery_level = Column(
        Float,
        nullable=True,
    )

    solar_status = Column(
        String,
        nullable=True,
    )

    communication_status = Column(
        String,
        nullable=True,
    )

    sensor_status = Column(
        String,
        nullable=True,
    )