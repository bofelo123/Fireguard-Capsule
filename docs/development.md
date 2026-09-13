# FireGuard Capsule™ Development Guide

## Developer Setup, Workflow and Engineering Guide

**Project:** FireGuard Capsule™
**Platform:** Flutter + FastAPI + AI/ML
**Database:** SQLite / SQLAlchemy
**Primary Backend Language:** Python
**Primary Frontend Language:** Dart
**Development Environment:** Windows
**Repository:** FireGuard Capsule™ source code

---

# 1. Purpose

This document explains how to set up, run, inspect, test, and develop the FireGuard Capsule platform.

FireGuard is a multi-layer engineering system consisting of:

```text
Flutter Application
        │
        ▼
FastAPI Backend
        │
        ├── Authentication
        ├── Telemetry
        ├── AI Analysis
        ├── Alerts
        ├── GIS
        ├── NASA FIRMS Intelligence
        └── FireGuard Assistant
        │
        ▼
SQLAlchemy / SQLite
        │
        ▼
AI / Environmental Intelligence
        │
        ▼
Future Physical FireGuard Capsule
```

The development workflow is designed to keep these layers separated while allowing them to be tested together.

---

# 2. Development Principles

FireGuard development follows these principles:

1. Build against real backend APIs.
2. Keep frontend and backend responsibilities separate.
3. Keep AI logic on the backend.
4. Keep database access on the backend.
5. Do not place secrets in source control.
6. Do not fabricate real-world sensor measurements.
7. Do not describe software-only tests as hardware validation.
8. Preserve scientific limitations of the AI model.
9. Verify changes before committing them.
10. Keep documentation synchronized with implementation.
11. Prefer reproducible development procedures.
12. Make changes incrementally and test them before moving to the next layer.

---

# 3. Repository Structure

The main project is organized approximately as follows:

```text
fireguard/
│
├── android/
├── ios/
├── linux/
├── macos/
├── windows/
│
├── lib/
│   ├── application code
│   ├── screens
│   ├── services
│   ├── repositories
│   ├── models
│   └── widgets
│
├── fireguard_backend/
│   ├── main.py
│   ├── database.py
│   ├── models.py
│   ├── schemas.py
│   │
│   └── ai/
│       ├── predictor.py
│       ├── nasa_fire_intelligence.py
│       ├── build_real_training_dataset.py
│       ├── train_real_fireguard_ai.py
│       ├── calibrate_fireguard_ai.py
│       └── data/
│
├── docs/
│   ├── architecture.md
│   ├── ai.md
│   ├── database.md
│   ├── api.md
│   └── development.md
│
├── pubspec.yaml
├── pubspec.lock
├── analysis_options.yaml
├── .gitignore
└── README.md
```

Some local files and generated artifacts are intentionally excluded from the public repository.

---

# 4. Required Development Tools

A developer working on FireGuard should have the appropriate tools installed.

## Flutter

Flutter is used for the FireGuard application.

Verify installation:

```powershell
flutter --version
```

Check the development environment:

```powershell
flutter doctor
```

---

# 5. Android Development

Android Studio and the Android SDK are required for Android development.

Check connected or available devices:

```powershell
flutter devices
```

The Android emulator can be started through Android Studio or the configured Android SDK tools.

---

# 6. Dart Dependencies

FireGuard dependencies are defined in:

```text
pubspec.yaml
```

Install dependencies with:

```powershell
flutter pub get
```

Do not manually edit generated dependency files unless there is a specific reason to do so.

---

# 7. Flutter Static Analysis

Before committing Flutter changes, run:

```powershell
flutter analyze
```

Review:

* errors
* warnings
* unused imports
* unused fields
* type problems
* deprecated APIs
* analyzer diagnostics

Not every analyzer message necessarily represents a functional failure, but errors should be addressed before considering a change complete.

---

# 8. Flutter Formatting

Format Dart source files with:

```powershell
dart format .
```

For a smaller change, a specific file or directory can be formatted instead.

Formatting keeps the codebase consistent and easier to review.

---

# 9. Flutter Tests

Run the Flutter test suite with:

```powershell
flutter test
```

When modifying a specific feature, targeted tests can be run where appropriate.

Tests should be expanded as production functionality grows.

---

# 10. Flutter Build Verification

For Android release/build verification:

```powershell
flutter build apk
```

The appropriate build mode should be selected according to the purpose of the test.

A successful build does not by itself prove that backend, AI, hardware, or production infrastructure is fully operational.

---

# 11. Backend Environment

The backend is located at:

```text
fireguard_backend/
```

Enter the backend directory:

```powershell
cd C:\FlutterProjects\livesti_guard\fireguard\fireguard_backend
```

---

# 12. Python Environment

A dedicated Python virtual environment is recommended.

Create one if required:

```powershell
python -m venv .venv
```

Activate it in PowerShell:

```powershell
.\.venv\Scripts\Activate.ps1
```

The virtual environment should remain outside version control.

It is already excluded by the repository `.gitignore`.

---

# 13. Backend Dependencies

Backend dependencies should be installed using the project's dependency configuration.

If a requirements file is provided:

```powershell
pip install -r requirements.txt
```

If the project uses another dependency-management mechanism, follow that project's configuration.

Developers should avoid installing undocumented dependencies only on their local machine because this can make the project difficult to reproduce.

---

# 14. Start the FastAPI Backend

From:

```text
C:\FlutterProjects\livesti_guard\fireguard\fireguard_backend
```

run:

```powershell
uvicorn main:app --reload
```

The development API should then be available at:

```text
http://127.0.0.1:8000
```

---

# 15. Verify the Backend

Open:

```text
http://127.0.0.1:8000/docs
```

This opens FastAPI's interactive Swagger documentation.

Also verify:

```text
http://127.0.0.1:8000/openapi.json
```

The generated OpenAPI schema is useful for checking the routes and request/response definitions exposed by the running backend.

---

# 16. Backend Source of Truth

The primary backend implementation files include:

```text
fireguard_backend/main.py
fireguard_backend/database.py
fireguard_backend/models.py
fireguard_backend/schemas.py
```

AI-related backend logic includes:

```text
fireguard_backend/ai/predictor.py
fireguard_backend/ai/nasa_fire_intelligence.py
```

Changes to API behavior should be made in the backend implementation rather than patched around in the Flutter interface.

---

# 17. Database Development

FireGuard currently uses SQLite with SQLAlchemy during development.

The database configuration is defined in:

```text
fireguard_backend/database.py
```

The development database is:

```text
fireguard_backend/fireguard.db
```

Database files are intentionally excluded from the public repository.

---

# 18. Database Inspection

Database inspection should be performed carefully.

Before modifying database structures:

1. Inspect the current schema.
2. Understand existing data.
3. Create a backup where appropriate.
4. Make the smallest required change.
5. Verify the resulting schema.
6. Test the backend against the changed database.

Do not delete a database simply because it appears empty or unfamiliar without first verifying which database the backend is actually using.

---

# 19. Database Models

The primary SQLAlchemy models are defined in:

```text
fireguard_backend/models.py
```

Current model areas include:

```text
User
Capsule
CapsuleTelemetry
Alert
FireIncident
RiskZone
```

The complete database architecture is documented in:

```text
docs/database.md
```

---

# 20. Telemetry Development

Telemetry is a central FireGuard subsystem.

The intended production flow is:

```text
Physical Sensors
      │
      ▼
FireGuard Capsule
      │
      ▼
Device Authentication
      │
      ▼
POST /api/device/telemetry
      │
      ▼
Backend Validation
      │
      ▼
Database
      │
      ▼
FireGuard AI
      │
      ▼
Alert
```

Telemetry fields can include:

* temperature
* smoke level
* humidity
* flame detection
* wind speed
* MQ-2
* MQ-7
* infrared temperature
* battery level
* solar status
* communication status
* sensor status
* latitude
* longitude

---

# 21. Wind Telemetry

Wind speed is part of the capsule telemetry model.

The database field is:

```text
wind_speed
```

The backend can pass wind information into the FireGuard AI analysis pipeline.

Developers should ensure that wind measurements are preserved from the physical device through the API and into the AI analysis layer.

The intended flow is:

```text
Wind Sensor
    │
    ▼
Device Telemetry
    │
    ▼
Backend
    │
    ▼
AI Analysis
    │
    ▼
Risk / Classification
```

---

# 22. Hardware Availability

The current software can be developed without permanent access to physical FireGuard hardware.

However, software testing and hardware validation must remain clearly separated.

### Software testing

Can verify:

* API contracts
* database behavior
* AI code
* Flutter UI
* application logic
* authentication
* error handling

### Hardware validation

Must verify:

* actual sensor readings
* physical sensor accuracy
* device connectivity
* GPS performance
* power system
* solar charging
* enclosure performance
* physical fire-response mechanism
* real environmental conditions

A software test must not be described as physical hardware validation.

---

# 23. No Fabricated Sensor Data

FireGuard follows a strict data-integrity principle.

If physical hardware is not connected, the system must not present invented values as though they were measured by a real FireGuard Capsule.

For example, developers should not describe an arbitrary temperature such as:

```text
42.3°C
```

as a real capsule observation unless it came from an actual sensor measurement.

Software test fixtures may exist where appropriate for automated testing, but they must remain clearly identified as test data and must never be represented as real field measurements.

---

# 24. AI Development

FireGuard's production AI implementation is located under:

```text
fireguard_backend/ai/
```

Important components include:

```text
predictor.py
build_real_training_dataset.py
train_real_fireguard_ai.py
calibrate_fireguard_ai.py
nasa_fire_intelligence.py
```

The AI architecture is documented in:

```text
docs/ai.md
```

---

# 25. Production Predictor

The production predictor is:

```text
fireguard_backend/ai/predictor.py
```

It combines engineering sensor evidence with environmental machine-learning evidence when valid environmental inputs are available.

The production model package is:

```text
fireguard_backend/ai/data/fireguard_calibrated_model.pkl
```

The predictor loads the model package lazily.

The model package contains the model and associated metadata required by the production predictor.

---

# 26. Environmental ML Features

The production environmental model uses four ERA5-derived features:

```text
era5_t2m_c
era5_d2m_c
era5_wind_speed_ms
era5_precip_m
```

The environmental model uses:

```text
RandomForestClassifier
```

with probability calibration using:

```text
IsotonicRegression
```

Environmental ML is only used when the required environmental data are actually available.

---

# 27. AI Training Data

The training workflow uses real external scientific data sources.

The documented training pipeline uses:

```text
NASA FIRMS
+
ERA5
```

The training dataset is constructed from NASA FIRMS fire-associated observations and controlled background observations.

The training process is documented in:

```text
docs/ai.md
```

Raw and large scientific datasets are intentionally excluded from the public source repository.

---

# 28. AI Training Workflow

The conceptual training workflow is:

```text
NASA FIRMS Fire Observations
             │
             ▼
      Environmental Join
             │
             ▼
     Controlled Background
             │
             ▼
     Training Dataset
             │
             ▼
   Chronological Evaluation
             │
             ▼
   Random Forest Training
             │
             ▼
 Probability Calibration
             │
             ▼
 Production Model Package
```

The scripts responsible for this workflow should be executed only when rebuilding or intentionally updating the model.

---

# 29. Training Dataset Generation

The dataset-building script is:

```text
fireguard_backend/ai/build_real_training_dataset.py
```

It creates the training dataset used by the FireGuard environmental model.

The generated training dataset is a local development artifact and is not intended to be committed to the public repository unless explicitly required by the project's data-distribution policy.

---

# 30. Model Training

The training script is:

```text
fireguard_backend/ai/train_real_fireguard_ai.py
```

The training process uses chronological ordering and a final time-based test period.

This is important because wildfire prediction systems should avoid evaluating a model using information from the future relative to the training observations.

The training configuration and evaluation methodology are documented in:

```text
docs/ai.md
```

---

# 31. Model Calibration

The calibration script is:

```text
fireguard_backend/ai/calibrate_fireguard_ai.py
```

The calibration process uses validation data and evaluates the final model on an untouched final test period.

The production model package contains the calibrated model and its metadata.

---

# 32. AI Evaluation

AI performance should be evaluated using more than one metric.

The current model documentation records metrics including:

* Brier score
* Log loss
* ROC-AUC
* PR-AUC

These metrics should not be interpreted as a guarantee of real-world wildfire detection performance.

Field validation is required before making claims about physical deployment performance.

---

# 33. AI Limitations

FireGuard's environmental ML model does not constitute perfect physical ground truth.

NASA FIRMS observations are satellite-derived observations and the controlled background definition is an engineered dataset construction method.

Therefore:

```text
Model probability
≠
Absolute physical probability of fire
```

The environmental estimate should be interpreted within the documented training-data definition and limitations.

---

# 34. Engineering Fire Evidence

FireGuard also uses engineering evidence from sensor measurements.

The production predictor evaluates signals including:

* flame detection
* smoke
* temperature
* humidity
* gas measurements
* infrared temperature
* wind
* environmental ML evidence when available

The engineering classification logic produces categories such as:

```text
NO_FIRE
SUSPECTED_FIRE
POSSIBLE_FIRE
CONFIRMED_FIRE
```

The exact logic is implemented in:

```text
fireguard_backend/ai/predictor.py
```

---

# 35. AI and Alert Integration

The backend AI flow is:

```text
Telemetry
   │
   ▼
predict_fire()
   │
   ▼
Classification
   │
   ▼
Severity / Risk
   │
   ├── NO_FIRE
   │
   └── Fire-related classification
          │
          ▼
       Alert
          │
          ▼
       Database
          │
          ▼
      Flutter Alerts
```

This integration keeps AI decision-making on the backend rather than embedding the complete decision system inside the Flutter application.

---

# 36. NASA FIRMS Development

NASA FIRMS functionality is implemented in:

```text
fireguard_backend/ai/nasa_fire_intelligence.py
```

NASA FIRMS is used as supporting satellite fire intelligence.

It should not be described as a replacement for FireGuard's capsule sensor system.

The backend keeps NASA-derived intelligence conceptually separate from physical capsule observations.

---

# 37. FireGuard Assistant Development

The backend assistant endpoint is:

```text
POST /api/ai/assistant
```

The assistant is designed to answer FireGuard-related questions using available system context.

It should not invent:

* current sensor measurements
* capsule readings
* fire incidents
* environmental observations
* GPS positions
* NASA detections

when those values are unavailable.

This is important for trustworthy operational communication.

---

# 38. Voice Interface Development

The Flutter application contains the user-facing voice/FireGuard Assistant interface.

The architecture is:

```text
Microphone
   │
   ▼
Flutter Voice Interface
   │
   ▼
Assistant Request
   │
   ▼
FastAPI
   │
   ▼
FireGuard Assistant
   │
   ▼
Response
   │
   ▼
Flutter Voice/Text UI
```

Voice interaction should remain a user-interface layer around the backend intelligence.

---

# 39. Flutter API Configuration

The Flutter application uses FireGuard API configuration rather than embedding endpoint URLs throughout individual screens.

The project includes a configuration mechanism based on:

```text
FIREGUARD_API_BASE_URL
```

During local development, the backend normally uses:

```text
http://127.0.0.1:8000
```

A production deployment should use the appropriate deployed API address and HTTPS.

---

# 40. Localhost and Android Emulator

Developers must remember that:

```text
127.0.0.1
```

inside an Android emulator refers to the emulator itself, not necessarily the Windows host machine.

When connecting an Android emulator to a backend running on the host computer, the appropriate emulator networking configuration should be used.

This is a development-environment issue and does not change the FireGuard API architecture.

---

# 41. Flutter Repository Layer

API calls should be kept in the application's service/repository layer where possible.

The conceptual pattern is:

```text
Screen
 │
 ▼
Repository / Service
 │
 ▼
HTTP Client
 │
 ▼
FastAPI
```

This reduces direct networking logic inside UI widgets and makes testing easier.

---

# 42. Changing an API Endpoint

When modifying an endpoint:

### Step 1

Inspect the current route in:

```text
fireguard_backend/main.py
```

### Step 2

Inspect the relevant request/response schemas in:

```text
fireguard_backend/schemas.py
```

### Step 3

Inspect related database models if the endpoint reads or writes persistent data:

```text
fireguard_backend/models.py
```

### Step 4

Make the smallest required implementation change.

### Step 5

Restart or allow Uvicorn reload.

### Step 6

Open:

```text
http://127.0.0.1:8000/docs
```

### Step 7

Test the changed endpoint.

### Step 8

Test the Flutter client that consumes the endpoint.

### Step 9

Run relevant tests and static analysis.

### Step 10

Inspect Git changes before committing.

---

# 43. Changing Database Models

Database model changes require additional care.

Before changing a model:

1. Inspect the existing database.
2. Confirm the current schema.
3. Understand whether existing records depend on the field.
4. Back up the development database when appropriate.
5. Change the SQLAlchemy model.
6. Update any schemas that expose the field.
7. Update API logic.
8. Update Flutter models/repositories if required.
9. Verify database behavior.
10. Test the complete request flow.

Do not assume that changing a Python model automatically provides safe production database migration behavior.

For production deployments, a formal migration strategy should be used.

---

# 44. Changing AI Logic

Before modifying:

```text
fireguard_backend/ai/predictor.py
```

inspect:

* feature names
* model loading
* classification rules
* missing-data behavior
* environmental ML logic
* confidence interpretation
* alert integration

After making changes:

1. Run the predictor tests.
2. Run backend tests where available.
3. Verify AI output on known test cases.
4. Check alert persistence.
5. Check the Flutter Alerts screen.
6. Review documentation for accuracy.

Do not change the model interpretation simply to make a UI result look better.

---

# 45. AI Model Replacement

Replacing the production model is a controlled change.

Before replacement:

* document the new training data
* document the feature set
* document the algorithm
* document the calibration method
* evaluate the model
* compare against the previous model
* update AI documentation
* verify production predictor compatibility

A new model should not be silently dropped into the production directory without documenting its provenance.

---

# 46. Testing Strategy

FireGuard testing should occur at several levels.

## Unit tests

Test individual functions and components.

Examples:

* AI predictor logic
* data validation
* repository methods
* utility functions

## Integration tests

Test interactions between:

* API and database
* telemetry and AI
* AI and alerts
* Flutter repositories and backend endpoints

## System tests

Test the complete application flow:

```text
Telemetry
→ AI
→ Alert
→ API
→ Flutter
```

## Hardware validation

Performed separately when physical FireGuard hardware is available.

---

# 47. Recommended Verification Sequence

When a significant backend change is made:

```text
1. Python syntax / import check
2. Backend startup
3. API route verification
4. Database verification
5. AI verification
6. Flutter analysis
7. Flutter tests
8. Application runtime test
9. Git diff review
```

This sequence helps isolate failures before they spread across multiple layers.

---

# 48. Git Workflow

The public FireGuard repository uses Git.

Before making a commit, inspect:

```powershell
git status
```

Then inspect the changes:

```powershell
git diff
```

For staged changes:

```powershell
git diff --cached
```

Check for whitespace errors:

```powershell
git diff --check
```

Only commit changes that have been reviewed.

---

# 49. Commit Messages

Commit messages should clearly describe the purpose of a change.

Good examples:

```text
Add production AI API documentation
```

```text
Fix wind speed telemetry persistence
```

```text
Document environmental ML pipeline
```

```text
Improve FireGuard assistant integration
```

Avoid vague messages such as:

```text
update
```

or:

```text
stuff
```

Clear commit history makes the engineering process easier to review.

---

# 50. Public Repository Safety

Before pushing to GitHub, inspect the repository for:

* passwords
* API keys
* private tokens
* `.env` files
* local databases
* private datasets
* personal credentials
* private certificates
* generated secrets
* unnecessary large binary files

Use:

```powershell
git status
```

and:

```powershell
git ls-files
```

to inspect tracked files.

The `.gitignore` file should prevent common local and secret files from entering the public repository.

---

# 51. AI Data Repository Policy

Large scientific datasets should not automatically be committed to the public repository.

The current repository excludes local scientific data such as:

```text
*.nc
*.csv
```

under the relevant AI data directories.

This keeps the source repository manageable while allowing the training pipeline to be documented and reproduced when the required datasets are available.

---

# 52. AI Model Artifact Policy

Production model artifacts require deliberate repository decisions.

The repository should not accidentally contain:

* obsolete models
* duplicate models
* temporary experiment artifacts
* training checkpoints
* local test models

The production model used by the predictor should be clearly identified.

Obsolete local artifacts should be classified before deletion.

---

# 53. Never Delete Before Inspection

When an unfamiliar file is found:

```text
DO NOT immediately delete it.
```

First determine:

1. What the file is.
2. Whether the application references it.
3. Whether the AI pipeline references it.
4. Whether it is tracked by Git.
5. Whether it is a backup.
6. Whether it is a generated artifact.
7. Whether it is required for reproduction.

Only then should the file be removed, ignored, archived, or retained.

This protects against accidental loss of project work.

---

# 54. Backup Policy

Before risky database or AI changes:

```text
Create a verified backup.
```

Backups should remain outside the public repository.

The repository `.gitignore` excludes common backup naming patterns.

Backups should not be treated as disposable until the replacement has been verified.

---

# 55. Environment Files

The repository should contain:

```text
.env.example
```

but not:

```text
.env
```

`.env.example` should contain placeholders rather than real credentials.

Example:

```text
FIREGUARD_API_BASE_URL=http://127.0.0.1:8000
```

Additional environment variables should be documented as the system grows.

---

# 56. Local Development Workflow

A normal development session can follow:

```text
Open project
    │
    ▼
Check Git status
    │
    ▼
Start backend
    │
    ▼
Verify API
    │
    ▼
Run Flutter application
    │
    ▼
Test feature
    │
    ▼
Run analysis/tests
    │
    ▼
Inspect Git diff
    │
    ▼
Commit intentional changes
```

This workflow keeps changes controlled and traceable.

---

# 57. Backend + Flutter Development

When developing a feature that crosses both layers:

### Backend first

1. Define or verify the API contract.
2. Implement backend logic.
3. Verify database behavior.
4. Test the endpoint.
5. Confirm the OpenAPI schema.

### Flutter second

1. Define/update the model.
2. Update repository/service.
3. Update screen/widget.
4. Handle loading states.
5. Handle error states.
6. Test against the live backend.

This approach reduces the risk of building a UI around an API that does not actually exist.

---

# 58. Alert Development Workflow

For an alert-related feature, verify the complete chain:

```text
Telemetry
    ↓
Backend
    ↓
AI
    ↓
Classification
    ↓
Alert Database Record
    ↓
GET /api/alerts
    ↓
Flutter Alert Repository
    ↓
Alerts Screen
    ↓
User Interaction
```

A UI notification alone is not considered a complete backend alert implementation.

The persisted database alert should be verified where the feature requires persistence.

---

# 59. FireGuard Assistant Development Workflow

For assistant functionality:

```text
User Question
    ↓
Flutter Assistant UI
    ↓
Backend Assistant API
    ↓
Available FireGuard Context
    ↓
Assistant Response
    ↓
Flutter
```

The assistant should preserve factual boundaries.

If current telemetry is unavailable, it should say so rather than inventing a reading.

---

# 60. API Documentation Maintenance

Whenever an endpoint is:

* added
* removed
* renamed
* changed
* secured
* given new request fields
* given new response fields

review:

```text
docs/api.md
```

and verify the live OpenAPI documentation.

Documentation should describe the actual system rather than an older intended design.

---

# 61. AI Documentation Maintenance

Whenever AI changes:

* model
* features
* training dataset
* calibration
* classification rules
* probability interpretation
* environmental data
* NASA intelligence integration

review:

```text
docs/ai.md
```

The AI documentation should remain scientifically honest and synchronized with implementation.

---

# 62. Database Documentation Maintenance

Whenever database models or persistence behavior changes, review:

```text
docs/database.md
```

Changes to telemetry fields, alerts, capsules, incidents, or risk zones should be reflected in the database documentation.

---

# 63. Architecture Documentation Maintenance

When major system boundaries change, review:

```text
docs/architecture.md
```

Examples include:

* new services
* new external data sources
* new hardware communication methods
* new AI architecture
* new database architecture
* new application layers

---

# 64. Debugging API Problems

When an API request fails:

### Step 1

Check that Uvicorn is running.

### Step 2

Check the backend terminal for an exception.

### Step 3

Open:

```text
http://127.0.0.1:8000/docs
```

### Step 4

Test the endpoint directly.

### Step 5

Check request data.

### Step 6

Check authentication.

### Step 7

Check database records if applicable.

### Step 8

Check Flutter logs.

### Step 9

Only then change code.

This prevents unnecessary changes caused by misunderstanding the source of a failure.

---

# 65. Debugging Flutter API Problems

When Flutter cannot communicate with the backend:

Check:

1. Backend is running.
2. API base URL is correct.
3. Android emulator networking is configured correctly.
4. Device/emulator has network access.
5. Endpoint exists.
6. Authentication is valid.
7. Request JSON matches the API schema.
8. Backend logs show the request.
9. Flutter logs show the response or error.

Do not immediately rewrite the repository or backend until the actual failure point is identified.

---

# 66. Debugging AI Problems

When AI output appears incorrect:

Check in this order:

```text
1. Input telemetry
2. Input validation
3. Environmental data availability
4. Feature names
5. Model loading
6. Predictor output
7. Classification logic
8. Alert persistence
9. Flutter display
```

This isolates whether the problem originates in:

* data
* backend
* model
* classification
* database
* UI

---

# 67. Reproducible Development

A new developer should be able to understand the project through:

```text
README.md
docs/architecture.md
docs/ai.md
docs/database.md
docs/api.md
docs/development.md
```

The source code remains the implementation authority.

The documentation explains the system architecture, scientific methodology, API behavior, database design, and development workflow.

---

# 68. Production Readiness Checklist

Before a production deployment, review:

### Backend

* [ ] Production server configuration
* [ ] HTTPS
* [ ] Authentication hardening
* [ ] Secret management
* [ ] Restricted CORS
* [ ] Rate limiting where appropriate
* [ ] Error monitoring
* [ ] Logging

### Database

* [ ] Production database selected
* [ ] Migration strategy
* [ ] Backup strategy
* [ ] Recovery testing
* [ ] Retention policy

### AI

* [ ] Model provenance documented
* [ ] Dataset provenance documented
* [ ] Evaluation completed
* [ ] Calibration verified
* [ ] Field validation planned/completed
* [ ] Model artifact versioned appropriately

### Hardware

* [ ] Sensor validation
* [ ] GPS validation
* [ ] Communications testing
* [ ] Power-system testing
* [ ] Environmental enclosure testing
* [ ] Physical fire-response validation

### Flutter

* [ ] Release build verified
* [ ] API configuration verified
* [ ] Error handling
* [ ] Authentication
* [ ] Alert workflow
* [ ] GIS functionality
* [ ] Assistant functionality

---

# 69. Engineering Validation

Software readiness should not be confused with complete field deployment readiness.

A successful software test demonstrates that the relevant software components work under the tested conditions.

It does not automatically prove:

* sensor accuracy
* wildfire detection accuracy in the field
* GPS accuracy under all conditions
* network reliability
* solar autonomy
* enclosure durability
* water-suppression performance
* long-term deployment reliability

These require physical engineering validation.

---

# 70. Scientific Integrity

FireGuard documentation and software should distinguish clearly between:

```text
Observed
```

```text
Calculated
```

```text
Model-estimated
```

```text
Externally sourced
```

For example:

```text
Sensor temperature
    = observed

AI risk estimate
    = model-estimated

NASA FIRMS fire observation
    = externally sourced satellite intelligence

Fire classification
    = calculated from FireGuard decision logic
```

This distinction should be preserved throughout the application.

---

# 71. Contribution Workflow

For a future contributor:

### 1. Understand the architecture

Read:

```text
docs/architecture.md
```

### 2. Understand AI

Read:

```text
docs/ai.md
```

### 3. Understand persistence

Read:

```text
docs/database.md
```

### 4. Understand APIs

Read:

```text
docs/api.md
```

### 5. Configure development

Follow this document.

### 6. Make a focused change

Avoid unrelated modifications.

### 7. Test

Run relevant backend and Flutter tests.

### 8. Inspect the diff

```powershell
git diff
```

### 9. Check repository state

```powershell
git status
```

### 10. Commit clearly

Use a descriptive commit message.

---

# 72. Pull Request Expectations

A future contribution should ideally explain:

* What changed.
* Why it changed.
* Which files were modified.
* How it was tested.
* Whether database changes are involved.
* Whether API behavior changed.
* Whether AI behavior changed.
* Whether Flutter behavior changed.
* Whether documentation was updated.

Large unrelated changes should be avoided.

---

# 73. Code Quality

FireGuard code should prioritize:

* readability
* maintainability
* explicit behavior
* meaningful names
* small focused changes
* clear error handling
* testability
* separation of concerns
* traceability

Code should not be made unnecessarily complex merely to appear sophisticated.

---

# 74. Development Rule: Verify Before Changing

When a problem appears:

```text
Observe
   ↓
Inspect
   ↓
Identify root cause
   ↓
Change
   ↓
Test
   ↓
Verify
```

Avoid:

```text
Guess
   ↓
Change many files
   ↓
Hope it works
```

This rule is especially important for FireGuard because Flutter, FastAPI, database, AI, and hardware integration are interconnected.

---

# 75. Development Rule: One Layer at a Time

When debugging a cross-layer issue, isolate the layers:

```text
Layer 1 — Flutter
Layer 2 — API
Layer 3 — Database
Layer 4 — AI
Layer 5 — External Intelligence
Layer 6 — Hardware
```

Do not modify all layers simultaneously unless the feature genuinely requires coordinated changes.

---

# 76. Development Rule: Preserve Working Functionality

When adding a feature:

1. Identify existing working behavior.
2. Make the smallest necessary change.
3. Test the new behavior.
4. Confirm existing behavior still works.
5. Only then continue.

This reduces regression risk.

---

# 77. Public Repository Quality Standard

Before the FireGuard repository is presented publicly, it should be reviewed for:

```text
✓ Clean structure
✓ Clear README
✓ Architecture documentation
✓ AI documentation
✓ Database documentation
✓ API documentation
✓ Development documentation
✓ License
✓ Environment example
✓ Secure .gitignore
✓ No secrets
✓ No private databases
✓ No unnecessary backups
✓ No obsolete tracked artifacts
✓ Reproducible setup instructions
✓ Verified Git history
✓ Working source code
```

The repository should communicate the engineering system clearly to a technical reviewer who has never seen the project before.

---

# 78. Final Developer Verification

Before a major public release:

```powershell
git status
```

Then:

```powershell
git diff --check
```

Then inspect the tracked file set:

```powershell
git ls-files
```

Run Flutter analysis:

```powershell
flutter analyze
```

Run Flutter tests:

```powershell
flutter test
```

Start the backend:

```powershell
cd .\fireguard_backend
uvicorn main:app --reload
```

Then verify:

```text
http://127.0.0.1:8000/docs
```

Finally, inspect the Git diff and staged files before creating the public commit.

---

# 79. Related Documentation

For the complete FireGuard technical documentation set:

```text
docs/architecture.md
docs/ai.md
docs/database.md
docs/api.md
docs/development.md
```

The project README provides the entry point for new users and reviewers.

---

# 80. Summary

FireGuard Capsule™ is developed as a connected engineering platform rather than as an isolated mobile application.

The development architecture is:

```text
Flutter
   │
   ▼
FastAPI
   │
   ├── Authentication
   ├── Telemetry
   ├── AI
   ├── Alerts
   ├── GIS
   ├── NASA FIRMS Intelligence
   └── FireGuard Assistant
   │
   ▼
Database
   │
   ▼
Environmental Intelligence
   │
   ▼
Future Physical Capsule Hardware
```

The development process prioritizes:

* real APIs
* real database persistence
* real AI/ML
* reproducibility
* responsible data interpretation
* scientific honesty
* secure configuration
* incremental verification
* maintainable source code
* clear public documentation

The ultimate goal is a FireGuard system that can be understood, tested, extended, and independently reviewed by engineers, researchers, developers, and future deployment partners.

---

**FireGuard Capsule™**
*AI-Powered Wildfire Monitoring, Early Warning and Early Response*
