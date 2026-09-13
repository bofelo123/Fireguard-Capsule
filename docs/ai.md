# FireGuard Capsule™ — Artificial Intelligence and Machine Learning

## 1. Purpose

FireGuard Capsule™ uses a layered fire-intelligence architecture designed to combine physical sensor evidence, engineering rules, environmental machine learning, and external satellite evidence.

The AI system is designed to support early wildfire detection and risk assessment while maintaining a clear distinction between:

- Real sensor observations
- Satellite observations
- Environmental datasets
- Machine-learning estimates
- Engineering rule-based classifications

The system does not treat machine-learning output as absolute proof that a physical fire exists.

---

## 2. AI Architecture

The FireGuard AI pipeline can be represented as:

```text
Real Capsule Telemetry
        │
        ▼
Sensor Validation
        │
        ▼
Engineering Fire-Evidence Rules
        │
        ├──────────────────────┐
        │                      │
        ▼                      ▼
Environmental ML        Fire Verification
        │                      │
        └──────────┬───────────┘
                   │
                   ▼
             Risk Assessment
                   │
                   ▼
          Fire Classification
                   │
        ┌──────────┼──────────┐
        ▼          ▼          ▼
     NO_FIRE   POSSIBLE    CONFIRMED
                   │
                   ▼
              Database AlertNASA FIRMS satellite intelligence can provide additional regional evidence but is not used as a replacement for local capsule sensing.

3. Production AI Predictor

The production predictor is located at:

fireguard_backend/ai/predictor.py

The predictor currently identifies itself as:

REAL_SENSOR_INTELLIGENCE_V2_WITH_ENVIRONMENTAL_ML_V1

The production environmental model is loaded from:

fireguard_backend/ai/data/fireguard_calibrated_model.pkl

The model is loaded lazily by the predictor rather than requiring the model to be loaded when the Python module is imported.

4. Environmental Machine-Learning Model

The environmental machine-learning component uses a Random Forest classifier.

The model package contains:

Trained Random Forest model
Isotonic calibration model
Feature column definitions
Target column definition
Model type
Calibration method
Training-data description
Background-observation definition
Probability definition
Validation calibration metrics
Final test metrics

The model type is:

RandomForestClassifier

The calibration method is:

IsotonicRegression
5. Environmental Features

The current environmental model uses four ERA5-derived features:

era5_t2m_c
era5_d2m_c
era5_wind_speed_ms
era5_precip_m

They represent:

Feature	Meaning
era5_t2m_c	ERA5 2-metre air temperature in °C
era5_d2m_c	ERA5 2-metre dew-point temperature in °C
era5_wind_speed_ms	ERA5 wind speed in metres per second
era5_precip_m	ERA5 precipitation in metres

The predictor only uses environmental machine-learning inference when all required ERA5 features are actually available.

The system does not fabricate missing environmental measurements.

6. Training Data

The FireGuard environmental training dataset combines:

NASA FIRMS fire-associated observations
ERA5 environmental conditions

The generated training dataset contains:

18,400 observations

The target classes are balanced:

fire_event = 0    9,200 observations
fire_event = 1    9,200 observations

The dataset contains the following principal fields:

latitude
longitude
datetime
era5_t2m_c
era5_d2m_c
era5_wind_speed_ms
era5_precip_m
fire_event
7. Positive Fire Observations

Positive observations are derived from NASA FIRMS fire-associated observations.

NASA FIRMS provides satellite-based fire detections and associated information.

These observations are treated as fire-associated training examples rather than perfect ground truth.

This distinction is important because satellite observations have limitations such as:

Spatial resolution
Temporal sampling
Detection conditions
Cloud and atmospheric effects
Sensor limitations
Possible omission of small or obscured fires

Therefore, the machine-learning model should not be described as learning from perfect ground-truth fire labels.

8. Controlled Background Observations

The negative class is generated using controlled background observations.

A background observation is selected at least:

0.4 degrees

from the nearest NASA FIRMS fire-associated observation and at least:

1 hour

from the nearest NASA positive observation.

This creates a defined background-selection procedure rather than simply assuming that every location without a satellite detection is guaranteed to contain no fire.

The resulting negative class represents controlled non-fire/background observations under the dataset-selection rules.

9. Training Pipeline

The real training workflow is implemented through Python scripts in:

fireguard_backend/ai/

The main stages are:

NASA FIRMS Data
        │
        ▼
ERA5 Environmental Data
        │
        ▼
Training Dataset Construction
        │
        ▼
Chronological Dataset Ordering
        │
        ▼
Training / Validation / Final Test
        │
        ▼
Random Forest Training
        │
        ▼
Probability Calibration
        │
        ▼
Calibrated Production Model

The dataset-building process is implemented by:

build_real_training_dataset.py

The real model-training process is implemented by:

train_real_fireguard_ai.py

The calibration process is implemented by:

calibrate_fireguard_ai.py
10. Temporal Evaluation

The training pipeline uses chronological ordering before creating the final evaluation set.

The newest 20% of observations are reserved as the final test period.

The earlier 80% is used for model development.

Within the development portion, a stratified training/validation split is used.

This structure provides a final time-separated evaluation set rather than evaluating the final model only on observations randomly mixed across the entire time period.

11. Random Forest Configuration

The current Random Forest configuration includes:

n_estimators = 400
max_depth = 12
min_samples_leaf = 4
class_weight = balanced
random_state = 42
n_jobs = -1

The fixed random state improves reproducibility of the training process.

12. Probability Calibration

The raw Random Forest probabilities are calibrated using:

IsotonicRegression

Calibration is fitted using the validation portion of the development dataset.

The untouched final test set is then used for final evaluation.

The production predictor therefore uses the calibrated environmental estimate rather than treating the raw Random Forest output as a directly calibrated probability.

13. Model Evaluation

The calibrated production model package currently records the following validation metrics:

Brier score: 0.03699
Log loss:    0.12297

The final test metrics are:

Brier score: 0.09901
Log loss:    0.30530
ROC-AUC:     0.96365
PR-AUC:      0.96508

These metrics describe performance on the specific dataset and evaluation methodology used during development.

They should not be interpreted as universal real-world wildfire-detection accuracy.

14. Meaning of the Environmental Estimate

The environmental ML output is an environmental fire-risk estimate.

It should not be described as:

The exact probability that a physical fire exists.

The model is trained using NASA FIRMS fire-associated observations and controlled background observations.

Therefore, its output is affected by:

The quality of NASA FIRMS observations
ERA5 environmental-data resolution
Dataset construction
Background-selection rules
Geographic coverage
Temporal coverage
Model assumptions
Calibration methodology

This limitation is intentionally documented so that the AI system is presented scientifically and honestly.

15. Engineering Fire Evidence

FireGuard does not rely solely on environmental machine learning.

The predictor also evaluates real capsule sensor evidence.

Examples include:

Flame detection
Temperature
Smoke level
Humidity
MQ-2 reading
MQ-7 reading
Infrared temperature
Wind speed

Engineering evidence is used to determine whether the sensor measurements indicate a meaningful fire condition.

16. Fire Classification

The production predictor can produce the following classifications:

NO_FIRE
SUSPECTED_FIRE
POSSIBLE_FIRE
CONFIRMED_FIRE

The classification logic combines sensor evidence and, where available, environmental ML evidence.

A confirmed fire classification requires strong fire evidence according to the implemented engineering rules.

The exact thresholds are implemented in:

fireguard_backend/ai/predictor.py

This keeps the production decision logic in source code rather than hiding it inside an opaque interface.

17. Sensor Evidence and ML Evidence

FireGuard distinguishes between two important concepts:

Sensor confidence

The predictor's confidence value represents agreement among available physical sensor evidence.

It should not automatically be interpreted as statistical machine-learning probability.

Environmental ML risk

The environmental model produces a calibrated environmental estimate based on ERA5 conditions.

These two concepts are intentionally kept separate.

This prevents a high sensor-agreement score from being incorrectly presented as a machine-learning probability.

18. Missing Environmental Data

If required ERA5 values are unavailable, the environmental ML component does not invent replacement values.

Instead, the predictor records that environmental intelligence is unavailable.

This allows the system to continue evaluating physical sensor evidence without fabricating environmental observations.

This design is important for real-world deployment where external environmental data may temporarily be unavailable.

19. NASA FIRMS Intelligence

The NASA FIRMS intelligence module is located at:

fireguard_backend/ai/nasa_fire_intelligence.py

It analyzes real NASA FIRMS fire observations.

The module provides satellite evidence and regional fire intelligence.

It is explicitly not intended to act as the primary local fire/no-fire classifier.

The distinction is:

FireGuard Capsule
        │
        └── Primary local sensing

NASA FIRMS
        │
        └── Supporting satellite evidence
20. Fire Verification

FireGuard also contains a fire-verification component:

fireguard_backend/ai/verification_engine.py

Verification can combine available evidence to support a more informed assessment of a detected event.

The purpose is to reduce reliance on a single measurement and provide additional evidence around potentially significant fire events.

21. Backend AI Integration

The FastAPI backend exposes AI functionality through API endpoints.

One important endpoint is:

POST /api/ai/analyze-alert

The endpoint accepts fire-related telemetry and passes the available information into the FireGuard predictor.

The resulting analysis can include:

Fire classification
Severity
Risk score
Confidence
Environmental ML information
Evidence
Explanation

When the analysis identifies a fire condition, the backend can create a persistent database alert.

22. Telemetry-to-AI Flow

The production-oriented flow is:

Real Capsule Telemetry
        │
        ▼
/api/device/telemetry
        │
        ▼
Telemetry Validation
        │
        ▼
ERA5 Environmental Lookup
        │
        ▼
FireGuard Predictor
        │
        ├── Sensor Evidence
        │
        ├── Engineering Rules
        │
        └── Environmental ML
        │
        ▼
Fire Classification
        │
        ▼
Severity / Risk
        │
        ▼
Database Alert
        │
        ▼
Flutter Alerts Screen

This is the intended path from real capsule measurements to an actionable FireGuard alert.

23. FireGuard Assistant

The FireGuard Assistant provides a natural-language interface over FireGuard intelligence.

It is designed to use actual available system information.

It should not:

Invent sensor measurements
Invent fire incidents
Claim that a capsule detected a fire when no evidence exists
Present unavailable environmental measurements as real
Replace the underlying FireGuard AI decision system

The assistant can use available:

Alerts
Capsule information
Fire analysis
NASA FIRMS evidence
Geographic information

The assistant is therefore an interaction layer over the FireGuard system rather than the source of the underlying fire detection decision.

24. Reproducibility

The AI workflow is implemented through source-code scripts rather than an undocumented training process.

The major reproducibility components include:

build_real_training_dataset.py
train_real_fireguard_ai.py
calibrate_fireguard_ai.py
predictor.py
verification_engine.py
nasa_fire_intelligence.py
era5_preprocessor.py
era5_runtime.py

Training datasets and large model artifacts are not committed to the public repository because of their size and data-distribution considerations.

The source code documents how the datasets are prepared and how the production model is consumed.

25. AI Data Policy

The public repository intentionally excludes:

Large ERA5 NetCDF files
Large NASA CSV datasets
Generated training datasets
Local model artifacts
Local AI backups
Temporary AI outputs

These files remain part of the development/training environment rather than being included in the source repository.

The repository therefore contains the AI implementation and reproducibility logic without unnecessarily distributing large generated artifacts.

26. Scientific Limitations

The FireGuard AI system is a prototype and development-stage wildfire intelligence system.

Important limitations include:

NASA FIRMS is satellite-based and does not observe every fire.
ERA5 is environmental reanalysis data rather than direct capsule measurements.
Training labels derived from satellite observations are not perfect ground truth.
Model performance depends on the geographic and temporal characteristics of the training data.
Environmental ML estimates should not be interpreted as guarantees of physical fire occurrence.
Real-world hardware deployment requires additional field validation.
Sensor calibration and environmental conditions can affect physical measurements.
Production deployment requires continued monitoring and model validation with new field data.

These limitations are part of the system's scientific documentation and should be considered during future validation.

27. Future AI Validation

Future development should expand validation using:

Longer time periods
More geographic regions
Additional fire seasons
More satellite observations
Real FireGuard capsule measurements
Controlled field tests
Sensor calibration experiments
False-positive analysis
False-negative analysis
Independent test datasets

The goal is to progressively validate the system under real operating conditions rather than assuming laboratory or dataset performance represents deployment performance.

28. AI Design Principles

FireGuard AI follows these principles:

Real data

Use real observations and clearly identify their source.

No fabricated measurements

Missing sensor or environmental values are not silently replaced with invented values.

Layered intelligence

Use sensor evidence, engineering rules, environmental ML, and satellite evidence as complementary information sources.

Explainability

Retain evidence and explanations associated with fire classifications.

Calibration

Use probability calibration where environmental ML estimates are presented.

Honest uncertainty

Do not describe model outputs as guarantees or absolute physical probabilities.

Reproducibility

Keep dataset construction, training, calibration, and inference logic documented in source code.

Continuous validation

Treat field testing and new real-world data as necessary stages of future AI development.


After pasting:

**Do this:** press **Ctrl + S**.

Then stop and tell me the result. We will verify `ai.md` before moving to `database.md`.