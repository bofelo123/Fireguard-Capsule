# FireGuard Capsule™ — Database Architecture

## 1. Overview

FireGuard Capsule™ uses a relational database to persist the operational information required by the wildfire monitoring and early-warning platform.

The current development database uses SQLite.

The database is accessed by the FastAPI backend and provides persistent storage for:

- Users
- FireGuard capsules
- Capsule telemetry
- Fire alerts
- Fire incidents
- Geographic risk zones

The database is intentionally kept outside the public source repository as a local runtime artifact.

---

## 2. Database Technology

The current development configuration uses:

```text
Database engine: SQLite
Python database layer: SQLAlchemy
Database file: fireguard.dbThe backend database configuration is implemented in:

fireguard_backend/database.py

The database URL is configured for local development using:

sqlite:///./fireguard.db

SQLite is appropriate for the current development and prototype environment because it is:

Lightweight
Serverless
Easy to deploy locally
Easy to back up
Suitable for development and testing
Supported directly by the Python backend

For larger production deployments, the persistence layer can be migrated to a managed relational database without changing the overall application architecture.

3. Database Location

The active development database is located inside:

fireguard_backend/

The database file is:

fireguard.db

Local database files are excluded from Git using the repository .gitignore.

This prevents local operational data, test records, authentication information, and development state from being accidentally published.

4. Database Models

The FireGuard backend currently defines the following primary database models:

User
Capsule
CapsuleTelemetry
Alert
FireIncident
RiskZone

The model definitions are implemented in:

fireguard_backend/models.py

These models represent the core persistent entities of the FireGuard platform.

5. Entity Relationship Overview

The logical relationship between the main entities can be represented as:

                         ┌──────────────┐
                         │     User     │
                         └──────┬───────┘
                                │
                                │ manages / accesses
                                ▼
                         ┌──────────────┐
                         │   Capsule    │
                         └──────┬───────┘
                                │
                         ┌──────┴───────┐
                         │              │
                         ▼              ▼
                ┌────────────────┐  ┌──────────────┐
                │ Capsule        │  │    Alert     │
                │ Telemetry      │  │              │
                └────────────────┘  └──────┬───────┘
                                            │
                                            ▼
                                    ┌──────────────┐
                                    │ FireIncident │
                                    └──────────────┘

                         ┌──────────────┐
                         │  RiskZone    │
                         └──────────────┘

The exact foreign-key relationships are defined in the SQLAlchemy models.

6. User Model

The User model represents authenticated FireGuard application users.

Users interact with the platform through the Flutter application and authenticated backend APIs.

Typical responsibilities include:

User authentication
Access to FireGuard monitoring information
Viewing alerts
Accessing dashboards
Interacting with FireGuard services

Authentication-related implementation is handled by the backend security modules.

Relevant backend files include:

fireguard_backend/security.py
fireguard_backend/main.py

Sensitive authentication information must not be committed to the public repository.

7. Capsule Model

The Capsule model represents a registered FireGuard monitoring device.

A capsule represents the physical FireGuard unit that is expected to collect environmental and fire-related measurements.

Capsule information can include identifiers and operational information used to distinguish individual devices.

The capsule identifier is important because telemetry and alerts must be associated with the correct physical monitoring unit.

The intended relationship is:

One Capsule
     │
     ├── Many telemetry records
     │
     └── Many associated alerts

This allows FireGuard to monitor multiple deployed capsules as part of a larger network.

8. Capsule Telemetry Model

The CapsuleTelemetry model stores measurements received from FireGuard capsules.

Telemetry is the primary data stream connecting the physical monitoring system to the backend intelligence layer.

The telemetry model includes measurements such as:

latitude
longitude
temperature
smoke_level
humidity
flame_detected
battery_level
solar_status
communication_status
sensor_status
mq2
mq7
infrared_temperature
wind_speed
recorded_at
capsule_id

The exact database schema is defined by the SQLAlchemy model in:

fireguard_backend/models.py
9. Wind Speed Telemetry

Wind speed is stored as part of capsule telemetry:

wind_speed

This field was added to the telemetry schema so that real wind measurements can flow through the FireGuard system.

The intended data path is:

Physical Wind Sensor
        │
        ▼
Capsule Telemetry
        │
        ▼
FastAPI Backend
        │
        ▼
Database
        │
        ▼
FireGuard AI
        │
        ▼
Fire Classification / Risk

Wind speed is therefore part of the real telemetry-to-AI architecture rather than being represented as a fixed UI value.

10. Telemetry Timestamp

Each telemetry record contains a recording timestamp.

The timestamp allows FireGuard to determine when an observation was captured.

This is important for:

Historical monitoring
Alert investigation
Environmental comparison
Time-series analysis
Fire-event reconstruction
Future model development

Telemetry records should therefore be treated as time-stamped observations rather than static device properties.

11. Geographic Telemetry

Telemetry can contain:

latitude
longitude

These values identify the geographic location associated with the capsule observation.

Geographic telemetry supports:

Map visualization
Fire location awareness
Capsule tracking
GIS analysis
Association with environmental information
Association with satellite fire observations

The Flutter application can use this information to display monitored locations geographically.

12. Alert Model

The Alert model stores fire-related alerts generated by the FireGuard backend.

An alert represents an event that requires attention from the user or monitoring operator.

An alert can contain information such as:

Alert title
Severity
Status
Capsule association
Fire classification
AI confidence
AI verification
Risk information
Sensor evidence
Environmental evidence
Geographic information
Alert timestamps

The alert model allows FireGuard to persist the result of an AI analysis rather than displaying only a temporary prediction.

13. Fire Classification

FireGuard alerts can contain classifications generated by the AI and engineering analysis layer.

The current classification system includes:

NO_FIRE
SUSPECTED_FIRE
POSSIBLE_FIRE
CONFIRMED_FIRE

The classification is produced by the FireGuard prediction system.

The database allows this result to be retained together with the supporting event information.

This creates an auditable relationship between:

Telemetry
   ↓
AI Analysis
   ↓
Classification
   ↓
Alert
14. Alert Severity

Alerts also contain severity information.

Severity allows the application to distinguish between events requiring different levels of attention.

The severity is determined by the FireGuard analysis pipeline using available sensor evidence, fire classification, and risk information.

The Flutter application uses this information to present alerts to users.

15. Alert Status

Alerts have a lifecycle rather than remaining permanently in one state.

The application supports operations including:

Acknowledge
Resolve

A simplified lifecycle is:

New Alert
    │
    ▼
Active
    │
    ▼
Acknowledged
    │
    ▼
Resolved

The exact status values are defined by the backend model and schemas.

This lifecycle allows operators to distinguish between:

Newly detected events
Events already reviewed
Events that have been handled
16. AI Evidence Stored With Alerts

FireGuard is designed to preserve evidence associated with AI-generated alerts.

This can include:

AI confidence
AI verification
Fire classification
Raw sensor information
Environmental information
AI analysis information
Supporting evidence

This is important because a wildfire monitoring system should not expose only a label such as:

CRITICAL

without retaining the information that contributed to the decision.

The stored evidence can support:

Investigation
Debugging
Model validation
Alert review
Future system improvements
17. Fire Incident Model

The FireIncident model represents a fire event at the incident level.

An incident provides a higher-level representation of a fire event than an individual telemetry observation.

This distinction is useful because a single wildfire may produce:

Multiple telemetry observations
Multiple alerts
Multiple sensor measurements
Multiple satellite observations

The incident concept provides a way to organize information around the broader event.

18. Risk Zone Model

The RiskZone model represents a geographic area associated with wildfire risk information.

Risk zones support the GIS and monitoring components of FireGuard.

They can be used to represent areas where environmental or operational conditions indicate increased fire risk.

Risk-zone information can be displayed through the FireGuard mapping interface.

19. Telemetry and AI Relationship

Telemetry is the primary input to the local FireGuard intelligence pipeline.

The intended flow is:

Capsule
   │
   ▼
Telemetry
   │
   ├── Stored in database
   │
   └── Sent through AI analysis
              │
              ▼
       Fire classification
              │
              ▼
           Alert

This allows FireGuard to maintain both:

The original observation
The resulting intelligence derived from that observation

This separation is important for auditability and future analysis.

20. Database and Environmental Intelligence

FireGuard can associate capsule observations with environmental information.

The AI pipeline can obtain ERA5 environmental values such as:

Temperature
Dew point
Wind speed
Precipitation

These values are used by the environmental machine-learning component when they are genuinely available.

The system is designed not to replace missing environmental measurements with fabricated values.

The database therefore remains the source of stored capsule observations, while environmental intelligence can be obtained through the AI/environmental-data layer.

21. Database and NASA FIRMS

NASA FIRMS provides satellite-based fire intelligence.

NASA FIRMS observations are used by the AI intelligence layer and are not intended to be confused with direct capsule telemetry.

The conceptual relationship is:

Capsule Telemetry
        │
        ▼
Local FireGuard Evidence
        │
        ├──────────────┐
        │              │
        ▼              ▼
   FireGuard AI    NASA FIRMS
        │              │
        └──────┬───────┘
               ▼
        Fire Intelligence

This distinction allows the system to preserve the source and meaning of different types of evidence.

22. Device Security

FireGuard devices require authentication when communicating with protected telemetry services.

The backend includes device-security functionality in:

fireguard_backend/device_security.py

Device tokens are protected using hashing rather than being stored as plain authentication secrets.

The intended device flow is:

FireGuard Capsule
        │
        ▼
Device Authentication
        │
        ▼
Authorized Telemetry Request
        │
        ▼
Telemetry Processing

This prevents arbitrary unauthenticated clients from being treated as trusted FireGuard capsules.

23. Database Initialization

The backend includes database initialization and table-creation functionality.

Relevant files include:

fireguard_backend/database.py
fireguard_backend/create_tables.py

The database initialization process creates the required SQLAlchemy tables for the backend models.

Development database inspection utilities are also included in the backend project.

24. Local Development Database

The local SQLite database is a runtime artifact.

It should not be committed to the public repository because it may contain:

User records
Device records
Telemetry
Alerts
Development data
Authentication-related information
Local testing state

The repository .gitignore therefore excludes:

*.db
*.sqlite
*.sqlite3

Developers should create their own local database when setting up the project.

25. Database Backups

Local database backups may exist during development for recovery and experimentation.

Examples include historical backup files kept in the local development environment.

These backups are intentionally excluded from the public repository.

Backup files should never be used as a substitute for a documented database initialization process.

26. Data Integrity Principles

FireGuard database design follows these principles:

Preserve source observations

Original telemetry should remain distinguishable from derived AI results.

Preserve timestamps

Observations should retain their recording time.

Preserve geographic context

Telemetry and incidents should retain geographic information where available.

Preserve AI evidence

Alerts should retain relevant evidence supporting the classification.

Separate entities

Capsules, telemetry, alerts, incidents, and risk zones are represented as separate concepts.

Protect authentication data

Authentication and device-security information must not expose sensitive credentials.

Keep local runtime data private

Local databases and backups are excluded from the public source repository.

27. Production Database Considerations

SQLite is currently appropriate for local development and prototype operation.

A larger production deployment may require a server-based relational database depending on:

Number of capsules
Telemetry frequency
Number of concurrent users
Geographic scale
Historical data volume
Availability requirements
Backup requirements
Disaster-recovery requirements

The application architecture should keep database access behind the backend data layer so that migration to a production database can be performed without redesigning the Flutter application.

28. Data Retention and Future Scaling

As FireGuard grows, telemetry may become a high-volume time-series dataset.

Future production improvements may include:

Scheduled archival
Time-based partitioning
Historical telemetry aggregation
Dedicated time-series storage
Automated backups
Replication
Monitoring
Disaster recovery
Data retention policies

These are deployment considerations for future scaling and do not change the current development architecture.

29. Database Documentation and Source of Truth

The database model definitions in:

fireguard_backend/models.py

are the source of truth for the current SQLAlchemy data model.

The backend schemas in:

fireguard_backend/schemas.py

define API-facing data structures associated with backend operations.

The database configuration is defined in:

fireguard_backend/database.py

The application logic connecting database records to API operations is implemented in:

fireguard_backend/main.py
30. Summary

The FireGuard database provides the persistent foundation connecting the physical monitoring concept, AI intelligence, backend services, and Flutter application.

The core relationship is:

Physical Capsule
      │
      ▼
Telemetry
      │
      ├──────────────► Database
      │
      ▼
FireGuard AI
      │
      ▼
Fire Classification
      │
      ▼
Alert
      │
      ▼
Flutter Application

The database is therefore not simply a storage component.

It provides the persistent evidence layer that allows FireGuard to connect observations, AI analysis, alerts, incidents, devices, and geographic information into one monitoring platform.


### After you paste it

**Do this:**

1. Press **Ctrl + S**.
2. Stop there.
3. Do **not** open or edit `api.md` yet.

Then tell me **“database saved”** and I will give you the next step.