from pathlib import Path

import joblib
import numpy as np
import pandas as pd

from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import (
    accuracy_score,
    average_precision_score,
    classification_report,
    confusion_matrix,
    f1_score,
    precision_score,
    recall_score,
    roc_auc_score,
)
from sklearn.model_selection import train_test_split


BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "data"

DATASET_FILE = DATA_DIR / "fireguard_training_dataset.csv"
MODEL_FILE = DATA_DIR / "fireguard_fire_model.pkl"


FEATURE_COLUMNS = [
    "era5_t2m_c",
    "era5_d2m_c",
    "era5_wind_speed_ms",
    "era5_precip_m",
]

TARGET_COLUMN = "fire_event"


print("========================================")
print("FIREGUARD REAL ML TRAINING")
print("========================================")
print()

print("Loading training dataset...")
df = pd.read_csv(DATASET_FILE, parse_dates=["datetime"])

print("ROWS:", len(df))
print("COLUMNS:", list(df.columns))
print()

# ---------------------------------------------------------------
# Validate required columns.
# ---------------------------------------------------------------

required_columns = FEATURE_COLUMNS + [
    TARGET_COLUMN,
    "latitude",
    "longitude",
    "datetime",
]

missing_columns = [
    column
    for column in required_columns
    if column not in df.columns
]

if missing_columns:
    raise ValueError(
        f"Missing required columns: {missing_columns}"
    )

# ---------------------------------------------------------------
# Validate data quality.
# ---------------------------------------------------------------

if df[required_columns].isna().any().any():
    raise ValueError(
        "Training dataset contains NULL values."
    )

if df.duplicated().any():
    raise ValueError(
        "Training dataset contains exact duplicate rows."
    )

labels = sorted(
    df[TARGET_COLUMN].astype(int).unique().tolist()
)

if labels != [0, 1]:
    raise ValueError(
        f"Expected target classes [0, 1], found {labels}"
    )

print("CLASS COUNTS:")
print(df[TARGET_COLUMN].value_counts().sort_index().to_string())
print()

# ---------------------------------------------------------------
# Sort chronologically.
#
# We keep the newest 20% as the final test set.
# This is more realistic than randomly mixing future observations
# into the training data.
# ---------------------------------------------------------------

df = df.sort_values("datetime").reset_index(drop=True)

test_start_index = int(len(df) * 0.80)

train_validation = df.iloc[:test_start_index].copy()
test = df.iloc[test_start_index:].copy()

print("CHRONOLOGICAL SPLIT")
print("----------------------------------------")
print("TRAIN/VALIDATION ROWS:", len(train_validation))
print("FINAL TEST ROWS:", len(test))
print()

print(
    "TRAIN/VALIDATION PERIOD:",
    train_validation["datetime"].min(),
    "to",
    train_validation["datetime"].max(),
)

print(
    "FINAL TEST PERIOD:",
    test["datetime"].min(),
    "to",
    test["datetime"].max(),
)
print()

# ---------------------------------------------------------------
# Split the earlier data into training and validation sets.
#
# Stratification preserves both fire/background classes.
# ---------------------------------------------------------------

X_train_validation = train_validation[FEATURE_COLUMNS]
y_train_validation = train_validation[TARGET_COLUMN].astype(int)

X_test = test[FEATURE_COLUMNS]
y_test = test[TARGET_COLUMN].astype(int)

X_train, X_validation, y_train, y_validation = train_test_split(
    X_train_validation,
    y_train_validation,
    test_size=0.20,
    random_state=42,
    stratify=y_train_validation,
)

print("MODEL SPLIT")
print("----------------------------------------")
print("TRAIN:", len(X_train))
print("VALIDATION:", len(X_validation))
print("TEST:", len(X_test))
print()

print("TRAIN CLASS COUNTS:")
print(y_train.value_counts().sort_index().to_string())
print()

print("VALIDATION CLASS COUNTS:")
print(y_validation.value_counts().sort_index().to_string())
print()

print("TEST CLASS COUNTS:")
print(y_test.value_counts().sort_index().to_string())
print()

# ---------------------------------------------------------------
# Train real Random Forest ML model.
#
# No synthetic sensor rows are generated here.
# The model learns only from the real NASA + ERA5 dataset.
# ---------------------------------------------------------------

print("Training Random Forest...")
print()

model = RandomForestClassifier(
    n_estimators=400,
    max_depth=12,
    min_samples_leaf=4,
    class_weight="balanced",
    random_state=42,
    n_jobs=-1,
)

model.fit(X_train, y_train)

print("MODEL TRAINING COMPLETE.")
print()

# ---------------------------------------------------------------
# Validation evaluation.
# ---------------------------------------------------------------

validation_predictions = model.predict(X_validation)
validation_probabilities = model.predict_proba(
    X_validation
)[:, 1]

validation_accuracy = accuracy_score(
    y_validation,
    validation_predictions,
)

validation_precision = precision_score(
    y_validation,
    validation_predictions,
    zero_division=0,
)

validation_recall = recall_score(
    y_validation,
    validation_predictions,
    zero_division=0,
)

validation_f1 = f1_score(
    y_validation,
    validation_predictions,
    zero_division=0,
)

validation_roc_auc = roc_auc_score(
    y_validation,
    validation_probabilities,
)

validation_pr_auc = average_precision_score(
    y_validation,
    validation_probabilities,
)

print("========================================")
print("VALIDATION RESULTS")
print("========================================")
print(f"Accuracy : {validation_accuracy:.4f}")
print(f"Precision: {validation_precision:.4f}")
print(f"Recall   : {validation_recall:.4f}")
print(f"F1       : {validation_f1:.4f}")
print(f"ROC-AUC  : {validation_roc_auc:.4f}")
print(f"PR-AUC   : {validation_pr_auc:.4f}")
print()

print("VALIDATION CLASSIFICATION REPORT:")
print(
    classification_report(
        y_validation,
        validation_predictions,
        target_names=[
            "Controlled background",
            "FIRMS fire-associated",
        ],
        zero_division=0,
    )
)

print("VALIDATION CONFUSION MATRIX:")
print(confusion_matrix(
    y_validation,
    validation_predictions,
))
print()

# ---------------------------------------------------------------
# Final untouched test evaluation.
#
# This dataset portion was not used to fit the model.
# ---------------------------------------------------------------

test_predictions = model.predict(X_test)
test_probabilities = model.predict_proba(X_test)[:, 1]

test_accuracy = accuracy_score(
    y_test,
    test_predictions,
)

test_precision = precision_score(
    y_test,
    test_predictions,
    zero_division=0,
)

test_recall = recall_score(
    y_test,
    test_predictions,
    zero_division=0,
)

test_f1 = f1_score(
    y_test,
    test_predictions,
    zero_division=0,
)

test_roc_auc = roc_auc_score(
    y_test,
    test_probabilities,
)

test_pr_auc = average_precision_score(
    y_test,
    test_probabilities,
)

print("========================================")
print("FINAL TEST RESULTS")
print("========================================")
print(f"Accuracy : {test_accuracy:.4f}")
print(f"Precision: {test_precision:.4f}")
print(f"Recall   : {test_recall:.4f}")
print(f"F1       : {test_f1:.4f}")
print(f"ROC-AUC  : {test_roc_auc:.4f}")
print(f"PR-AUC   : {test_pr_auc:.4f}")
print()

print("FINAL TEST CLASSIFICATION REPORT:")
print(
    classification_report(
        y_test,
        test_predictions,
        target_names=[
            "Controlled background",
            "FIRMS fire-associated",
        ],
        zero_division=0,
    )
)

print("FINAL TEST CONFUSION MATRIX:")
print(confusion_matrix(
    y_test,
    test_predictions,
))
print()

# ---------------------------------------------------------------
# Feature importance.
# ---------------------------------------------------------------

feature_importance = pd.Series(
    model.feature_importances_,
    index=FEATURE_COLUMNS,
).sort_values(ascending=False)

print("FEATURE IMPORTANCE:")
print(feature_importance.to_string())
print()

# ---------------------------------------------------------------
# Save model and metadata.
# ---------------------------------------------------------------

model_package = {
    "model": model,
    "feature_columns": FEATURE_COLUMNS,
    "target_column": TARGET_COLUMN,
    "model_type": "RandomForestClassifier",
    "training_data": "NASA FIRMS + ERA5",
    "background_definition": (
        "Controlled background observations selected "
        "at least 0.4 degrees and 1 hour from nearest "
        "NASA FIRMS fire-associated observation."
    ),
    "validation_metrics": {
        "accuracy": validation_accuracy,
        "precision": validation_precision,
        "recall": validation_recall,
        "f1": validation_f1,
        "roc_auc": validation_roc_auc,
        "pr_auc": validation_pr_auc,
    },
    "test_metrics": {
        "accuracy": test_accuracy,
        "precision": test_precision,
        "recall": test_recall,
        "f1": test_f1,
        "roc_auc": test_roc_auc,
        "pr_auc": test_pr_auc,
    },
}

joblib.dump(
    model_package,
    MODEL_FILE,
)

print("========================================")
print("REAL ML MODEL SAVED")
print("========================================")
print("MODEL:", MODEL_FILE)
print()
print("IMPORTANT:")
print(
    "The model probability is not yet presented as a "
    "calibrated probability. Calibration will be handled "
    "before production API integration."
)
print()
print("MODEL READY FOR CALIBRATION: YES")
