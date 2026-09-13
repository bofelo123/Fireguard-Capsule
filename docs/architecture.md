# FireGuard Capsule™ — System Architecture

## 1. Overview

FireGuard Capsule™ is an AI-powered wildfire monitoring, early warning, and early-response system designed for fire-prone environments.

The system combines:

- Autonomous environmental sensing
- Real-time telemetry
- GPS/GNSS location
- FastAPI backend services
- SQLite database storage
- Fire-event intelligence and verification
- Environmental machine learning
- NASA FIRMS satellite fire intelligence
- Flutter mobile/web user interface
- Alert generation and monitoring
- Optional hardware capsule integration

The architecture is designed so that physical FireGuard capsules can send real telemetry to the backend while the software platform can also be developed and tested independently of the physical hardware.

---

## 2. High-Level Architecture

```text
                    ┌───────────────────────────┐
                    │     FireGuard Capsule     │
                    │       Hardware Layer      │
                    │                           │
                    │ Temperature               │
                    │ Smoke / MQ Sensors        │
                    │ Humidity                  │
                    │ Infrared Temperature      │
                    │ Flame Detection            │
                    │ Wind Speed                 │
                    │ GPS / GNSS                │
                    │ Battery / Solar            │
                    └─────────────┬─────────────┘
                                  │
                                  │ Real Telemetry
                                  ▼
                    ┌───────────────────────────┐
                    │       FastAPI Backend     │
                    │                           │
                    │ Authentication            │
                    │ Device Security           │
                    │ Telemetry API             │
                    │ Alert API                 │
                    │ Capsule Management        │
                    │ GIS Services              │
                    │ AI Services               │
                    └─────────────┬─────────────┘
                                  │
             ┌────────────────────┼────────────────────┐
             │                    │                    │
             ▼                    ▼                    ▼
    ┌────────────────┐   ┌────────────────┐   ┌──────────────────┐
    │ SQLite Database │   │ FireGuard AI   │   │ NASA FIRMS /    │
    │                │   │ Intelligence   │   │ ERA5 Evidence   │
    │ Users          │   │                │   │                  │
    │ Capsules       │   │ Sensor rules   │   │ Satellite fire   │
    │ Telemetry      │   │ Environmental  │   │ observations     │
    │ Alerts         │   │ ML             │   │                  │
    │ Fire Incidents │   │ Verification   │   │ Weather          │
    │ Risk Zones     │   │ Calibration    │   │ conditions       │
    └───────┬────────┘   └───────┬────────┘   └────────┬─────────┘
            │                    │                     │
            └────────────────────┼─────────────────────┘
                                 │
                                 ▼
                    ┌───────────────────────────┐
                    │      FireGuard Flutter    │
                    │          Application      │
                    │                           │
                    │ Dashboard                 │
                    │ Alerts                   │
                    │ Maps / GIS                │
                    │ Capsule Monitoring        │
                    │ FireGuard Assistant        │
                    │ Notifications              │
                    └───────────────────────────┘3. Main Software Components
3.1 Flutter Frontend

The Flutter application provides the primary user interface.

The frontend is responsible for:

User authentication
Dashboard visualization
Fire alerts
Capsule monitoring
Telemetry visualization
GIS/map visualization
Alert acknowledgement and resolution
FireGuard Assistant interaction
Connection/status information

The Flutter application communicates with the FastAPI backend through HTTP APIs.

The API base URL is configured through:

FIREGUARD_API_BASE_URL

A development fallback is available for local development.

4. FastAPI Backend

The backend is implemented using FastAPI.

Main responsibilities include:

Authentication
User management
Capsule registration
Device authentication
Telemetry ingestion
Telemetry retrieval
AI fire analysis
Alert creation
Alert acknowledgement
Alert resolution
Fire incident management
Risk-zone services
GIS services
NASA fire intelligence
FireGuard Assistant services

The backend is located in:

fireguard_backend/

The primary application entry point is:

fireguard_backend/main.py

The development server can be started with:

cd fireguard_backend
uvicorn main:app --reload
5. Database Layer

FireGuard uses SQLite for local development and prototype deployment.

The database is created and managed by the backend.

The main database entities include:

User
Capsule
CapsuleTelemetry
Alert
FireIncident
RiskZone

The database stores operational FireGuard information including:

Registered users
Registered capsules
Sensor telemetry
Fire classifications
AI evidence
Alert states
Fire incidents
Geographic risk information

Local database files are intentionally excluded from the public source repository.

See:

docs/database.md

for the database design.

6. Telemetry Flow

The intended production telemetry path is:

Physical Capsule
       │
       ▼
Sensor Measurements
       │
       ▼
Device Telemetry API
       │
       ▼
Telemetry Validation
       │
       ▼
Database Storage
       │
       ▼
FireGuard AI Analysis
       │
       ▼
Fire Classification
       │
       ▼
Alert Generation
       │
       ▼
Flutter Alerts Screen

Telemetry can contain measurements including:

Latitude
Longitude
Temperature
Smoke level
Humidity
Flame detection
Wind speed
MQ-2 gas/smoke reading
MQ-7 carbon-monoxide-related reading
Infrared temperature
Battery level
Solar status
Communication status
Sensor status

The system is designed so that real hardware telemetry can be integrated without replacing the backend architecture.

7. Fire Analysis Pipeline

FireGuard uses a layered analysis approach rather than relying on a single sensor or a single machine-learning output.

The analysis combines:

Physical sensor evidence
Engineering threshold rules
Environmental machine-learning evidence
Optional satellite evidence
Fire verification logic

The resulting analysis can classify an event as:

NO_FIRE
SUSPECTED_FIRE
POSSIBLE_FIRE
CONFIRMED_FIRE

The backend can create a persistent alert when the analysis identifies a fire condition requiring attention.

8. Environmental Machine Learning

The environmental ML component uses real NASA FIRMS fire-associated observations together with ERA5 environmental data.

The current model uses environmental variables including:

2 m air temperature
2 m dew-point temperature
Wind speed
Precipitation

The production model is stored as a calibrated model package under the AI data directory.

Large scientific datasets and generated model artifacts are intentionally excluded from the public repository.

The model is not treated as absolute physical truth.

Its output is an environmental fire-risk estimate based on the training data and controlled background observations.

See:

docs/ai.md

for the complete AI methodology and limitations.

9. NASA FIRMS Integration

NASA FIRMS data provides satellite-based fire detection evidence.

FireGuard uses NASA FIRMS as supporting intelligence rather than treating satellite detections as a replacement for local capsule sensing.

The NASA intelligence module:

fireguard_backend/ai/nasa_fire_intelligence.py

analyzes real NASA FIRMS fire observations.

This allows the platform to provide broader regional fire intelligence while the FireGuard capsule remains the primary local sensing concept.

10. Alert Lifecycle

A typical alert follows this process:

Telemetry Received
       │
       ▼
AI / Engineering Analysis
       │
       ├── NO_FIRE
       │
       └── Fire Evidence
              │
              ▼
       Fire Classification
              │
              ▼
       Severity / Risk Assessment
              │
              ▼
       Database Alert
              │
              ▼
       Flutter Alert Screen
              │
        ┌─────┴─────┐
        ▼           ▼
   Acknowledge    Resolve

Alerts retain relevant evidence so that the event can be investigated rather than presenting only a simple severity label.

11. FireGuard Assistant

The FireGuard Assistant provides a natural-language interface for querying available FireGuard information.

The assistant is designed around actual system information.

It should not fabricate sensor readings or claim that a physical capsule has detected a fire when no corresponding evidence exists.

Where appropriate, it can use:

Current FireGuard alerts
Capsule information
AI analysis
NASA FIRMS evidence
Available geographic information

The assistant is therefore an interface to FireGuard intelligence rather than a replacement for the underlying monitoring system.

12. GIS Layer

FireGuard provides geographic information for:

Fire incidents
Risk zones
Registered capsules
Fire-related observations

The Flutter application can display this information through its mapping interface.

Geographic information is intended to help users understand where an event is occurring and how it relates to monitored areas.

13. Security Architecture

The backend includes authentication and device-security mechanisms.

Application users authenticate through the backend authentication system.

Registered devices use device credentials/tokens for telemetry access.

Device tokens are not stored as plain credentials in the database; the backend uses token hashing for device authentication.

Secrets and environment-specific configuration are not intended to be committed to the public repository.

14. Repository Architecture

The public source repository is organized around the following major components:

Fireguard-Capsule/
│
├── lib/                       # Flutter application
├── test/                      # Flutter tests
├── assets/                    # Application assets
│
├── fireguard_backend/         # FastAPI backend
│   ├── main.py
│   ├── database.py
│   ├── models.py
│   ├── schemas.py
│   ├── security.py
│   ├── device_security.py
│   ├── requirements.txt
│   └── ai/
│
├── fireguard_hardware/        # Hardware firmware
│
├── docs/                      # Technical documentation
│   ├── architecture.md
│   ├── ai.md
│   ├── database.md
│   ├── api.md
│   └── development.md
│
├── pubspec.yaml               # Flutter dependencies
├── analysis_options.yaml      # Dart analysis configuration
└── README.md                  # Project overview and setup

The repository intentionally excludes local databases, private configuration, large raw scientific datasets, generated build files, and local backup files.

15. Hardware Availability

At the current software-development stage, the physical FireGuard capsule hardware is not connected to the development environment.

This repository therefore documents and implements the real software interfaces required for future hardware integration without representing simulated sensor readings as real-world measurements.

When the hardware is available, the capsule can communicate with the existing telemetry API using the documented device-authentication mechanism.

16. Design Principles

FireGuard follows these principles:

Real data over fabricated data

The system should distinguish real sensor observations, satellite observations, environmental datasets, and model-derived estimates.

Explainable decisions

Fire classifications should retain supporting evidence instead of exposing only an unexplained prediction.

Layered intelligence

Sensor evidence, engineering rules, environmental ML, and satellite evidence are treated as complementary sources.

Hardware-independent software development

The software platform can be developed and validated before physical capsule deployment.

Reproducibility

AI training data preparation, model training, calibration, and runtime inference are implemented as documented Python components.

Security by design

Authentication, device authorization, environment configuration, and secret management are treated as part of the system architecture.

Clear separation of responsibilities

The Flutter application handles presentation, the FastAPI backend handles services and orchestration, the database handles persistence, and the AI layer handles fire intelligence.

17. Related Documentation
AI and Machine Learning
Database Architecture
API Reference
Development Guide

**After pasting:** press **Ctrl + S**.

Then **stop**. Don't edit the other four files yet.