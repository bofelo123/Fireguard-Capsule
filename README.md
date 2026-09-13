FireGuard Capsule

AI-Powered Wildfire Monitoring, Early Warning & Early-Response System



FireGuard Capsule is a production-oriented wildfire intelligence and early-response platform designed to support earlier detection, evidence-based fire assessment, location-aware alerting, and operational situational awareness.



The platform combines:



Real environmental and capsule telemetry

Sensor-evidence-based fire classification

Environmental machine learning using ERA5 data

NASA FIRMS satellite fire intelligence

FastAPI backend services

SQLite database persistence for local development

Flutter mobile/web user interfaces

GIS-based fire and capsule visualization

FireGuard Assistant for natural-language operational queries

A hardware integration architecture designed for solar-powered wildfire monitoring capsules



Project status: Active engineering and validation project. Hardware deployment is not currently connected to this development environment. The software is designed to integrate with physical FireGuard capsules through the documented telemetry API when hardware becomes available.



## 1. Overview



Wildfires can develop rapidly under combinations of high temperature, dry vegetation, low humidity, wind, and ignition sources. In remote and fire-prone environments, delayed detection can increase the time available for a fire to spread before appropriate response begins.



FireGuard Capsule is designed around an evidence-driven monitoring pipeline:



Physical FireGuard Capsule

        |

        | Sensor telemetry

        v

FastAPI Backend

        |

        |-- Sensor validation

        |-- Database persistence

        |-- Environmental data lookup

        |

        v

FireGuard AI

        |

        |-- Engineering sensor evidence

        |-- Environmental ML risk estimate

        `-- Fire classification

        |

        v

Alert Generation

        |

        |-- Severity

        |-- Risk score

        |-- AI evidence

        |-- GPS location

        `-- Alert status

        |

        v

Flutter Application

        |

        |-- Alerts

        |-- Dashboard

        |-- GIS / Map

        |-- Capsule status

        `-- FireGuard Assistant



The system is intentionally designed so that real sensor measurements remain the source of physical fire evidence. Environmental machine learning and external satellite intelligence provide supporting evidence rather than being presented as perfect ground truth.



## 2. Core Objectives



FireGuard Capsule is designed to help provide:



Earlier wildfire detection

Location-aware fire alerts

Evidence-based fire classification

Environmental fire-risk assessment

Satellite-based supporting intelligence

Persistent alert records

Operational situational awareness

A foundation for future physical fire-response capabilities

A reproducible software and AI development workflow

## 3. Key System Capabilities

3.1 Capsule Telemetry



The backend accepts telemetry associated with FireGuard capsules, including measurements such as:



Latitude

Longitude

Temperature

Humidity

Smoke level

CO-related sensor measurements

Infrared temperature

Flame detection

Wind speed

Battery level

Solar status

Communication status

Sensor status

Timestamp



Wind speed is treated as a real telemetry field and is propagated through the backend analysis pipeline rather than being generated as fabricated sensor data.



3.2 Fire Classification



FireGuard's production predictor combines engineering sensor evidence with environmental intelligence.



The current engineering classifications are:



Classification	Meaning

NO_FIRE	Available evidence does not meet the configured fire-event criteria

SUSPECTED_FIRE	Evidence indicates a possible developing fire condition

POSSIBLE_FIRE	Multiple indicators provide meaningful evidence of fire

CONFIRMED_FIRE	Strong sensor evidence satisfies the configured confirmation logic



Classification is intentionally based on multiple evidence sources rather than a single sensor reading.



3.3 Environmental Machine Learning



FireGuard includes a real machine-learning model trained using environmental observations derived from:



NASA FIRMS fire observations

ERA5 environmental data



The production environmental model uses:



era5_t2m_c

era5_d2m_c

era5_wind_speed_ms

era5_precip_m



The current model is a calibrated:



RandomForestClassifier

        +

IsotonicRegression calibration



The environmental model provides an environmental fire-risk estimate.



It is not presented as an absolute physical probability that a fire exists at a particular location.



This distinction is important because satellite observations and controlled background labels do not constitute perfect ground truth for every physical fire condition.



## 4. AI Methodology



The AI pipeline is designed to remain scientifically traceable and reproducible.



Training data



The current training dataset contains:



18,400 observations

9,200 positive observations

9,200 controlled background observations



The dataset combines geographic and temporal information with four ERA5 environmental variables.



Positive observations



Positive observations are associated with NASA FIRMS fire detections.



Controlled background



Background observations are selected using spatial and temporal separation from the nearest NASA FIRMS fire-associated observation.



The current construction uses a minimum separation of approximately:



0.4 degrees

\+

1 hour

Evaluation



The training workflow uses chronological ordering so that the newest portion of the dataset is retained as a final test period.



The model development process includes:



Dataset construction

Data validation

Chronological split

Training/validation split

Random Forest training

Probability calibration

Validation evaluation

Final untouched test evaluation

Model packaging

Production prediction



The detailed methodology is documented in:



docs/ai.md

fireguard_backend/ai/build_real_training_dataset.py

fireguard_backend/ai/train_real_fireguard_ai.py

fireguard_backend/ai/calibrate_fireguard_ai.py

fireguard_backend/ai/predictor.py

## 5. Model Evaluation



The current calibrated model package records evaluation metrics for transparency.



Current final-test metrics include approximately:



Metric	Result

ROC-AUC	0.964

PR-AUC	0.965

Brier score	0.099

Log loss	0.305



Validation calibration metrics are also stored with the model package.



These metrics describe performance on the current dataset and evaluation design. They do not guarantee real-world wildfire detection performance.



Real-world validation requires deployment-oriented testing with representative sensor measurements, environmental conditions, geographic variation, and independently collected fire-event observations.



## 6. Sensor Evidence + Environmental Intelligence



FireGuard intentionally separates two different forms of evidence.



Physical sensor evidence



This represents measurements associated with a FireGuard capsule, such as:



Flame detection

Smoke

Temperature

Infrared temperature

CO-related measurements

Humidity

Wind

Other telemetry health indicators

Environmental ML evidence



The machine-learning model evaluates environmental conditions using ERA5 variables.



These two evidence sources are combined by the production predictor to support the final fire classification, severity, and risk assessment.



The architecture therefore avoids treating environmental ML alone as proof that a physical fire exists.



## 7. NASA FIRMS Integration



FireGuard also provides NASA FIRMS-based fire intelligence.



NASA FIRMS is used as supporting satellite intelligence for identifying fire detections and activity in relevant geographic areas.



The NASA intelligence layer is deliberately separated from the capsule fire classifier.



Conceptually:



FireGuard Capsule Sensors

        |

        `-- Physical fire evidence



ERA5 + Environmental ML

        |

        `-- Environmental risk evidence



NASA FIRMS

        |

        `-- Satellite fire intelligence



              v



        FireGuard Decision Layer



NASA FIRMS therefore supports situational awareness and verification without being incorrectly represented as perfect ground truth for every local event.



## 8. Backend



FireGuard's backend is implemented with:



Python

FastAPI

SQLAlchemy

SQLite for local development



The backend provides services for:



Authentication

Dashboard data

Capsule management

Telemetry ingestion

Telemetry retrieval

AI fire analysis

Alert generation

Alert acknowledgement

Alert resolution

NASA fire intelligence

Fire verification

GIS data

FireGuard Assistant



Local backend development uses:



http://127.0.0.1:8000



FastAPI automatically exposes interactive OpenAPI documentation when the development server is running.



## 9. Database



The local development database uses SQLite through SQLAlchemy.



Primary entities include:



User

Capsule

CapsuleTelemetry

Alert

FireIncident

RiskZone



Telemetry is persisted before being used by downstream analysis workflows.



Alert records can retain AI-related evidence, including:



AI confidence

Fire classification

Verification result

Sensor evidence

Environmental information

Analysis metadata



The local database is intentionally excluded from the public repository.



See:



docs/database.md



## 10. Alert Lifecycle



A typical alert flow is:



Telemetry received

        v

Telemetry validated

        v

Telemetry persisted

        v

Environmental information retrieved when available

        v

FireGuard predictor evaluates evidence

        v

Classification generated

        v

Severity / risk calculated

        v

Alert created when configured criteria are met

        v

Flutter application retrieves alert

        v

User reviews alert

        v

Acknowledgement

        v

Resolution



This creates a persistent operational record rather than treating an alert as a temporary UI message.



## 11. Flutter Application



The frontend is built with Flutter and provides the operational user interface.



The application includes functionality for:



Authentication

Dashboard

Fire alerts

Alert details

Capsule information

Telemetry information

Maps and GIS information

Fire intelligence

FireGuard Assistant

Voice interaction

Alert acknowledgement and resolution



The Flutter application communicates with the FastAPI backend rather than directly accessing the database.



## 12. FireGuard Assistant



FireGuard includes a domain-specific assistant designed for operational questions.



Examples include:



What is the current fire situation?

Are there any active critical alerts?

What is happening around this capsule?

What is the latest fire intelligence?



The assistant is designed to use available FireGuard context rather than inventing sensor measurements.



Where relevant, its context can include:



Active alerts

Capsule information

Fire classifications

AI analysis

NASA fire intelligence

Geographic information



Voice interaction is implemented as a Flutter user-interface capability around the assistant workflow.



## 13. GIS and Situational Awareness



FireGuard includes geographic visualization for operational awareness.



The platform can work with:



Fire incidents

NASA fire intelligence

Risk zones

Capsule locations

Latitude/longitude telemetry



The Flutter application uses map-based visualization to help users understand the geographic relationship between capsules, fire activity, and risk information.



## 14. Hardware Architecture



FireGuard Capsule is designed around an autonomous field capsule concept.



The intended hardware architecture can include:



Environmental sensors

Smoke/gas sensing

Flame/infrared sensing

Temperature and humidity sensing

Wind measurement

GPS/GNSS

Microcontroller

Solar power

Rechargeable battery

Wireless communication

Weather-resistant enclosure

Future localized fire-response mechanism



The software repository contains the integration architecture needed for telemetry communication.



Current hardware status



Physical capsule hardware is not currently connected to this development environment.



The project does not represent simulated measurements as live hardware measurements.



When physical hardware becomes available, it will communicate through the documented telemetry API.



## 15. No Fabricated Sensor Data Policy



A core FireGuard engineering principle is:



Do not represent fabricated or simulated measurements as real-world sensor observations.



The absence of physical hardware does not justify inventing sensor readings.



For development and testing, software components can be tested using explicitly identified test inputs and controlled test procedures.



These must remain distinguishable from production telemetry.



This principle is especially important for:



AI evaluation

Alert generation

Scientific reporting

Competition demonstrations

Hardware integration

Public documentation

## 16. Repository Structure



The repository is organized approximately as follows:



fireguard/

|

|-- android/

|-- ios/

|-- linux/

|-- macos/

|-- web/

|-- windows/

|

|-- assets/

|

|-- lib/

|   `-- Flutter application source

|

|-- test/

|   `-- Flutter tests

|

|-- fireguard_backend/

|   |-- ai/

|   |   |-- predictor.py

|   |   |-- build_real_training_dataset.py

|   |   |-- train_real_fireguard_ai.py

|   |   |-- calibrate_fireguard_ai.py

|   |   `-- nasa_fire_intelligence.py

|   |

|   |-- main.py

|   |-- database.py

|   |-- models.py

|   `-- schemas.py

|

|-- fireguard_hardware/

|

|-- docs/

|   |-- architecture.md

|   |-- ai.md

|   |-- database.md

|   |-- api.md

|   `-- development.md

|

|-- .env.example

|-- .gitignore

|-- LICENSE

|-- README.md

|-- analysis_options.yaml

|-- pubspec.yaml

`-- pubspec.lock



Local databases, backups, raw scientific datasets, generated model artifacts, secrets, build outputs, and other development-only files are excluded according to the repository policy.



## 17. Documentation



Detailed technical documentation is available in the docs/ directory.



Architecture



docs/architecture.md



Explains the complete system architecture and interaction between the Flutter application, backend, database, AI, environmental intelligence, GIS, and future hardware.



AI



docs/ai.md



Documents:



Dataset construction

NASA FIRMS observations

ERA5 environmental variables

Model architecture

Training methodology

Calibration

Evaluation

Fire classification

Scientific limitations

Reproducibility

Database



docs/database.md



Documents:



Database technology

Entities

Relationships

Telemetry

Alerts

AI evidence

Security-related data

Development database practices

API



docs/api.md



Documents:



Authentication

Telemetry

Alerts

AI endpoints

NASA intelligence

GIS

Assistant

Development workflow

API security principles

Development



docs/development.md



Documents:



Local development

Flutter workflow

Backend workflow

AI workflow

Testing

Git workflow

Repository safety

Debugging

Reproducibility

Engineering validation

## 18. Getting Started

Prerequisites



Install the development tools appropriate for your platform.



Core requirements include:



Flutter SDK

Dart SDK through Flutter

Python 3.x

Git

Android Studio for Android development where required

A suitable Python environment for backend and AI development



Verify Flutter:



flutter --version



Verify Python:



python --version



Verify Git:



git --version

## 19. Configure Environment



The repository includes:



.env.example



Copy the example configuration into a local environment configuration as appropriate for the development setup.



Never commit real secrets.



Do not place the following in Git:



Passwords

API keys

Device tokens

Private keys

Production credentials

Secret database credentials

## 20. Run the Backend



Move into the backend directory:



cd fireguard_backend



Start the FastAPI development server:



uvicorn main:app --reload



The local backend is normally available at:



http://127.0.0.1:8000



FastAPI's interactive API documentation can then be accessed through the server's OpenAPI interface.



For the authoritative endpoint behavior, always refer to the running API documentation and:



docs/api.md



## 21. Run the Flutter Application



From the repository root:



flutter pub get



Check the project:



flutter analyze



Format Dart code:



dart format .



Run tests:



flutter test



Then launch the application using an available Flutter device:



flutter devices



and:



flutter run



The backend must be reachable from the selected Flutter target.



For Android emulators, the host-machine address commonly differs from desktop localhost. See:



docs/development.md



## 22. Development Workflow



A recommended development cycle is:



1. Understand the change

        v

2. Inspect existing implementation

        v

3. Change one layer

        v

4. Run the relevant verification

        v

5. Inspect the result

        v

6. Continue to the next layer



For example, a telemetry change should normally be traced through:



Flutter / hardware payload

        v

API schema

        v

FastAPI endpoint

        v

Database model

        v

AI analysis

        v

Alert

        v

Flutter alert UI



This reduces the risk of changing one component while leaving another component inconsistent.



## 23. Testing and Verification



FireGuard development uses multiple verification layers.



Flutter

flutter analyze

flutter test

Backend



Use the FastAPI OpenAPI interface and direct API testing to verify:



Authentication

Telemetry

Alerts

AI analysis

GIS

Assistant behavior

AI



Verify:



Dataset integrity

Class balance

Missing values

Duplicate records

Training reproducibility

Validation metrics

Final test metrics

Model metadata

Prediction behavior

End-to-end



Where the required infrastructure is available, verify:



Telemetry

-> database

-> AI

-> alert

-> API

-> Flutter UI

## 24. Reproducibility



FireGuard's AI workflow is designed to be reproducible.



Important training characteristics include:



Explicit feature definitions

Explicit target definition

Fixed random seeds where appropriate

Controlled dataset construction

Chronological evaluation

Documented model configuration

Stored model metadata

Recorded evaluation metrics

Explicit probability interpretation



The training data and generated model artifacts are intentionally not automatically committed to the public repository when they are large, generated, local, or otherwise unsuitable for source control.



See:



docs/ai.md



for the complete methodology.



## 25. Scientific and Engineering Limitations



FireGuard is an engineering and research-oriented system under continued validation.



Important limitations include:



Satellite observations are not perfect ground truth



NASA FIRMS provides valuable satellite fire intelligence, but satellite detections have limitations in spatial resolution, temporal coverage, detection conditions, and observation uncertainty.



Environmental ML is not a physical fire detector



The environmental model estimates environmental fire-event risk from ERA5-derived conditions and training labels.



It should not be interpreted as proof that a physical fire exists.



Sensor evidence requires physical validation



Real-world sensor performance depends on:



Sensor selection

Calibration

Installation geometry

Weather conditions

Environmental interference

Sensor ageing

Power availability

Communication reliability

Model performance requires broader validation



Current evaluation results describe the available dataset and evaluation methodology.



Additional geographically diverse, independently collected, real-world validation is required before making deployment-level performance claims.



## 26. Security Principles



FireGuard follows basic security practices including:



Authentication

Device-token-based telemetry authorization

Token hashing where implemented

Separation of secrets from source code

Environment-based configuration

Local database exclusion from Git

Public-repository secret protection

Explicit API boundaries



Production deployment should additionally use:



HTTPS/TLS

Secure secret management

Production-grade database infrastructure

Strong authentication policies

Access control

Monitoring and audit logging

Secure device provisioning

Key rotation

Infrastructure hardening

## 27. Public Repository Policy



This repository is intended to expose the engineering implementation without exposing private operational data or secrets.



The public repository should not contain:



.env

database files

database backups

API keys

device tokens

private credentials

private keys

raw proprietary datasets

unnecessary generated artifacts

local IDE state

build output



The repository's .gitignore is configured to exclude important local and generated artifacts.



Before every public push, inspect:



git status



and review staged changes before committing.



## 28. Intellectual and Engineering Scope



FireGuard Capsule combines multiple engineering disciplines:



Mechanical engineering

Embedded systems

Electrical/electronics integration

Environmental sensing

Wireless communication

Software engineering

Machine learning

Geographic information systems

Data engineering

Human-computer interaction

Wildfire intelligence



The project is designed as a system rather than as an isolated machine-learning model.



## 29. Future Development



Planned engineering areas include:



Physical capsule prototype validation

Sensor calibration

Field telemetry validation

Long-range communication validation

Solar/battery performance testing

Weather-resistant enclosure testing

Fire-response mechanism validation

Broader geographic AI validation

Independent model evaluation

Production database deployment

Secure device provisioning

Operational monitoring

Larger-scale capsule networking



These future capabilities should be validated experimentally before being represented as deployed capabilities.



## 30. Responsible AI Position



FireGuard treats AI as a decision-support component within a broader engineering system.



The system is designed to:



Preserve data provenance

Distinguish sensor evidence from model estimates

Avoid fabricated measurements

Document model limitations

Preserve evaluation methodology

Avoid presenting uncertain predictions as guaranteed facts

Maintain traceability from telemetry to alert

Support human operational decision-making



The goal is not simply to produce a high model score.



The goal is to build an understandable, testable, reproducible, and responsibly engineered wildfire intelligence system.



## 31. Contribution



Development should follow the documented engineering workflow.



Before submitting changes:



Understand the existing implementation.

Make the smallest appropriate change.

Preserve existing working functionality.

Run relevant tests.

Run static analysis where applicable.

Review the Git diff.

Update documentation when behavior changes.

Never commit secrets or private operational data.



See:



docs/development.md



## 32. License



FireGuard Capsule source code is released under the MIT License.



See:



LICENSE



for the complete license text.



## 33. Project Documentation

Document	Purpose

docs/architecture.md	Complete system architecture

docs/ai.md	AI methodology and validation

docs/database.md	Database architecture and data model

docs/api.md	Backend API documentation

docs/development.md	Developer setup and workflow

LICENSE	Open-source license

.env.example	Safe configuration template

## 34. Summary



FireGuard Capsule is being developed as a complete wildfire intelligence and early-response platform rather than as a standalone AI demonstration.



Its architecture connects:



Real telemetry

     +

Environmental intelligence

     +

Machine learning

     +

Satellite fire intelligence

     +

Persistent database records

     +

Backend APIs

     +

GIS

     +

Flutter operations interface

     +

FireGuard Assistant

     v

Evidence-driven wildfire situational awareness



The project prioritizes engineering integrity, scientific transparency, reproducibility, traceability, and responsible AI development.



The software architecture is designed to evolve from development and validation toward physical capsule integration and field testing as the required hardware and validation infrastructure become available.



FireGuard Capsule



AI-Powered Wildfire Monitoring, Early Warning & Early-Response System



Built as an engineering platform for earlier wildfire intelligence, evidence-based alerting, and future autonomous field response.










