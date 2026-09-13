from pathlib import Path

import joblib
import numpy as np
import pandas as pd

from sklearn.isotonic import IsotonicRegression
from sklearn.metrics import (
    brier_score_loss,
    log_loss,
    roc_auc_score,
    average_precision_score,
)


BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "data"

DATASET_FILE = DATA_DIR / "fireguard_training_dataset.csv"
MODEL_FILE = DATA_DIR / "fireguard_fire_model.pkl"
CALIBRATED_FILE = DATA_DIR / "fireguard_calibrated_model.pkl"


FEATURE_COLUMNS = [
    "era5_t2m_c",
    "era5_d2m_c",
    "era5_wind_speed_ms",
    "era5_precip_m",
]

TARGET_COLUMN = "fire_event"


print("========================================")
print("FIREGUARD ML PROBABILITY CALIBRATION")
print("========================================")
print()

print("Loading trained model...")
package = joblib.load(MODEL_FILE)

model = package["model"]

print("Loading training dataset...")
df = pd.read_csv(
    DATASET_FILE,
    parse_dates=["datetime"],
)

df = df.sort_values("datetime").reset_index(drop=True)

# ---------------------------------------------------------------
# Recreate the exact chronological split used during training.
# ---------------------------------------------------------------

test_start_index = int(len(df) * 0.80)

train_validation = df.iloc[:test_start_index].copy()
test = df.iloc[test_start_index:].copy()

X_train_validation = train_validation[FEATURE_COLUMNS]
y_train_validation = train_validation[TARGET_COLUMN].astype(int)

X_test = test[FEATURE_COLUMNS]
y_test = test[TARGET_COLUMN].astype(int)

# ---------------------------------------------------------------
# Recreate the exact validation split used during training.
# ---------------------------------------------------------------

from sklearn.model_selection import train_test_split

X_train, X_validation, y_train, y_validation = train_test_split(
    X_train_validation,
    y_train_validation,
    test_size=0.20,
    random_state=42,
    stratify=y_train_validation,
)

print("TRAIN:", len(X_train))
print("VALIDATION:", len(X_validation))
print("TEST:", len(X_test))
print()

# ---------------------------------------------------------------
# IMPORTANT:
# The saved Random Forest was fitted on X_train.
#
# We therefore obtain probabilities on the untouched validation
# observations and fit ONLY the calibration mapping on them.
# ---------------------------------------------------------------

print("Generating validation probabilities...")

validation_probabilities = model.predict_proba(
    X_validation
)[:, 1]

print("Validation probability range:")
print(
    f"MIN: {validation_probabilities.min():.6f}"
)
print(
    f"MAX: {validation_probabilities.max():.6f}"
)
print(
    f"MEAN: {validation_probabilities.mean():.6f}"
)
print()

# ---------------------------------------------------------------
# Isotonic calibration.
#
# This learns a monotonic mapping from the Random Forest's raw
# probability estimates to empirically calibrated probabilities.
# ---------------------------------------------------------------

print("Fitting isotonic calibration...")

calibrator = IsotonicRegression(
    y_min=0.0,
    y_max=1.0,
    out_of_bounds="clip",
)

calibrator.fit(
    validation_probabilities,
    y_validation.to_numpy(),
)

print("Calibration complete.")
print()

# ---------------------------------------------------------------
# Evaluate calibration on validation data.
# ---------------------------------------------------------------

validation_calibrated = calibrator.predict(
    validation_probabilities
)

validation_brier = brier_score_loss(
    y_validation,
    validation_calibrated,
)

validation_logloss = log_loss(
    y_validation,
    np.clip(
        validation_calibrated,
        1e-6,
        1 - 1e-6,
    ),
)

print("========================================")
print("CALIBRATED VALIDATION RESULTS")
print("========================================")
print(
    f"Brier score: {validation_brier:.6f}"
)
print(
    f"Log loss   : {validation_logloss:.6f}"
)
print(
    f"ROC-AUC    : {roc_auc_score(y_validation, validation_calibrated):.6f}"
)
print(
    f"PR-AUC     : {average_precision_score(y_validation, validation_calibrated):.6f}"
)
print()

# ---------------------------------------------------------------
# Evaluate calibrated probabilities on the untouched test set.
#
# The test labels were never used to fit the calibrator.
# ---------------------------------------------------------------

print("Evaluating calibrated probabilities on final test set...")

test_raw_probabilities = model.predict_proba(
    X_test
)[:, 1]

test_calibrated_probabilities = calibrator.predict(
    test_raw_probabilities
)

test_brier = brier_score_loss(
    y_test,
    test_calibrated_probabilities,
)

test_logloss = log_loss(
    y_test,
    np.clip(
        test_calibrated_probabilities,
        1e-6,
        1 - 1e-6,
    ),
)

test_roc_auc = roc_auc_score(
    y_test,
    test_calibrated_probabilities,
)

test_pr_auc = average_precision_score(
    y_test,
    test_calibrated_probabilities,
)

print()
print("========================================")
print("CALIBRATED FINAL TEST RESULTS")
print("========================================")
print(
    f"Brier score: {test_brier:.6f}"
)
print(
    f"Log loss   : {test_logloss:.6f}"
)
print(
    f"ROC-AUC    : {test_roc_auc:.6f}"
)
print(
    f"PR-AUC     : {test_pr_auc:.6f}"
)
print()

print("CALIBRATED PROBABILITY RANGE:")
print(
    f"MIN: {test_calibrated_probabilities.min():.6f}"
)
print(
    f"MAX: {test_calibrated_probabilities.max():.6f}"
)
print()

# ---------------------------------------------------------------
# Save the model + calibration layer together.
# ---------------------------------------------------------------

calibrated_package = {
    "model": model,
    "calibrator": calibrator,
    "feature_columns": FEATURE_COLUMNS,
    "target_column": TARGET_COLUMN,
    "model_type": "RandomForestClassifier",
    "calibration_method": "IsotonicRegression",
    "training_data": "NASA FIRMS + ERA5",
    "background_definition": (
        "Controlled background observations selected "
        "at least 0.4 degrees and 1 hour from nearest "
        "NASA FIRMS fire-associated observation."
    ),
    "probability_definition": (
        "Calibrated estimate produced from the model's "
        "validation-set probabilities. It is not an "
        "absolute probability of physical fire because "
        "NASA FIRMS observations and controlled background "
        "labels are not perfect ground truth."
    ),
    "validation_calibration_metrics": {
        "brier_score": validation_brier,
        "log_loss": validation_logloss,
    },
    "test_calibration_metrics": {
        "brier_score": test_brier,
        "log_loss": test_logloss,
        "roc_auc": test_roc_auc,
        "pr_auc": test_pr_auc,
    },
}

joblib.dump(
    calibrated_package,
    CALIBRATED_FILE,
)

print("========================================")
print("CALIBRATED MODEL SAVED")
print("========================================")
print("MODEL:", CALIBRATED_FILE)
print()
print("PRODUCTION CALIBRATION STATUS: COMPLETE")
