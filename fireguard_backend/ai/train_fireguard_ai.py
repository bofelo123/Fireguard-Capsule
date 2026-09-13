from pathlib import Path
import joblib
import pandas as pd

from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import (
    accuracy_score,
    precision_score,
    recall_score,
    f1_score,
    classification_report,
)


# ============================================================
# FireGuard Capsule™
# Real AI Training Pipeline
# ============================================================

BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "data"

TRAINING_DATASET = DATA_DIR / "fireguard_training_dataset.csv"
MODEL_OUTPUT = BASE_DIR / "fire_model_production.pkl"


# ------------------------------------------------------------
# Features used by the environmental FireGuard AI
# ------------------------------------------------------------

FEATURE_COLUMNS = [
    "temperature_c",
    "relative_humidity_percent",
    "wind_speed_mps",
    "precipitation_mm",
]


TARGET_COLUMN = "fire_event"


# ------------------------------------------------------------
# Load and validate dataset
# ------------------------------------------------------------

def load_training_dataset() -> pd.DataFrame:

    print("=" * 70)
    print("FireGuard Capsule™ - Real AI Training")
    print("=" * 70)

    print("\n[1/7] Checking training dataset...")

    if not TRAINING_DATASET.exists():

        raise FileNotFoundError(
            "\nTraining dataset was not found:\n"
            f"{TRAINING_DATASET}\n\n"
            "FireGuard AI will NOT train without a valid real "
            "training dataset."
        )

    print(f"Dataset: {TRAINING_DATASET}")

    df = pd.read_csv(TRAINING_DATASET)

    print(f"Rows: {len(df):,}")
    print(f"Columns: {len(df.columns)}")

    return df


# ------------------------------------------------------------
# Validate columns
# ------------------------------------------------------------

def validate_columns(df: pd.DataFrame):

    print("\n[2/7] Checking required columns...")

    required = FEATURE_COLUMNS + [TARGET_COLUMN]

    missing = [
        column
        for column in required
        if column not in df.columns
    ]

    if missing:

        raise ValueError(
            "\nMissing required columns:\n"
            + "\n".join(f" - {column}" for column in missing)
        )

    print("Required columns are present.")


# ------------------------------------------------------------
# Validate values
# ------------------------------------------------------------

def validate_values(df: pd.DataFrame):

    print("\n[3/7] Checking data quality...")

    selected = df[FEATURE_COLUMNS + [TARGET_COLUMN]]

    missing = selected.isnull().sum()

    if missing.sum() > 0:

        print("\nMissing values:")

        for column, count in missing.items():

            if count > 0:
                print(f" - {column}: {count:,}")

        raise ValueError(
            "\nMissing values detected. "
            "Training stopped."
        )

    duplicates = df.duplicated().sum()

    print(f"Duplicate rows: {duplicates:,}")

    if duplicates > 0:

        raise ValueError(
            "\nDuplicate observations detected. "
            "Training stopped."
        )

    labels = sorted(df[TARGET_COLUMN].unique().tolist())

    print(f"Fire-event labels: {labels}")

    if not set(labels).issubset({0, 1}):

        raise ValueError(
            "\nfire_event must contain only 0 and 1."
        )

    if len(labels) != 2:

        raise ValueError(
            "\nThe dataset does not contain both fire and "
            "non-fire observations."
        )

    fire_count = int(
        (df[TARGET_COLUMN] == 1).sum()
    )

    non_fire_count = int(
        (df[TARGET_COLUMN] == 0).sum()
    )

    print(f"Fire observations:     {fire_count:,}")
    print(f"Non-fire observations: {non_fire_count:,}")


# ------------------------------------------------------------
# Prepare X and y
# ------------------------------------------------------------

def prepare_features(df: pd.DataFrame):

    print("\n[4/7] Preparing AI features...")

    X = df[FEATURE_COLUMNS].copy()
    y = df[TARGET_COLUMN].astype(int)

    print("\nAI features:")

    for feature in FEATURE_COLUMNS:
        print(f" - {feature}")

    print(f"\nTarget: {TARGET_COLUMN}")

    return X, y


# ------------------------------------------------------------
# Train model
# ------------------------------------------------------------

def train_model(X: pd.DataFrame, y: pd.Series):

    print("\n[5/7] Training FireGuard AI...")

    # --------------------------------------------------------
    # IMPORTANT:
    # This first training implementation is intentionally
    # conservative. A proper temporal/geographic validation
    # split will be applied once the matched dataset contains
    # the required timestamp/location fields.
    # --------------------------------------------------------

    split_index = int(len(X) * 0.80)

    if split_index <= 0 or split_index >= len(X):

        raise ValueError(
            "Dataset is too small for training."
        )

    X_train = X.iloc[:split_index]
    X_test = X.iloc[split_index:]

    y_train = y.iloc[:split_index]
    y_test = y.iloc[split_index:]

    if y_train.nunique() < 2:

        raise ValueError(
            "Training portion contains only one class."
        )

    if y_test.nunique() < 2:

        raise ValueError(
            "Validation portion contains only one class."
        )

    model = RandomForestClassifier(
        n_estimators=300,
        random_state=42,
        class_weight="balanced",
        n_jobs=-1,
    )

    model.fit(X_train, y_train)

    predictions = model.predict(X_test)

    return model, y_test, predictions


# ------------------------------------------------------------
# Evaluate model
# ------------------------------------------------------------

def evaluate_model(y_test, predictions):

    print("\n[6/7] Evaluating FireGuard AI...")

    accuracy = accuracy_score(
        y_test,
        predictions,
    )

    precision = precision_score(
        y_test,
        predictions,
        zero_division=0,
    )

    recall = recall_score(
        y_test,
        predictions,
        zero_division=0,
    )

    f1 = f1_score(
        y_test,
        predictions,
        zero_division=0,
    )

    print()
    print(f"Accuracy : {accuracy:.4f}")
    print(f"Precision: {precision:.4f}")
    print(f"Recall   : {recall:.4f}")
    print(f"F1 Score : {f1:.4f}")

    print("\nClassification report:")
    print(
        classification_report(
            y_test,
            predictions,
            zero_division=0,
        )
    )

    return {
        "accuracy": accuracy,
        "precision": precision,
        "recall": recall,
        "f1": f1,
    }


# ------------------------------------------------------------
# Save model
# ------------------------------------------------------------

def save_model(model, metrics):

    print("\n[7/7] Saving FireGuard AI model...")

    package = {
        "model": model,
        "features": FEATURE_COLUMNS,
        "metrics": metrics,
        "version": "fireguard-ai-1.0",
    }

    joblib.dump(
        package,
        MODEL_OUTPUT,
    )

    print(f"\nModel saved to:")
    print(MODEL_OUTPUT)

    print("\n" + "=" * 70)
    print("FIREGUARD AI TRAINING COMPLETE")
    print("=" * 70)


# ------------------------------------------------------------
# Main
# ------------------------------------------------------------

def main():

    df = load_training_dataset()

    validate_columns(df)

    validate_values(df)

    X, y = prepare_features(df)

    model, y_test, predictions = train_model(
        X,
        y,
    )

    metrics = evaluate_model(
        y_test,
        predictions,
    )

    save_model(
        model,
        metrics,
    )


if __name__ == "__main__":
    main()