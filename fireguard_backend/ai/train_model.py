import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
import joblib
import os


# ============================================================
# FIREGUARD AI TRAINING DATA
# ============================================================
#
# 0 = NO FIRE
# 1 = FIRE
#
# Prototype synthetic dataset.
# Real field data should be added later.
# ============================================================

data = {
    "temperature": [
        # NO FIRE
        20, 22, 24, 25, 27, 28, 30, 31, 26, 29,
        32, 33, 30, 27, 25, 23, 35, 34, 31, 28,

        # FIRE
        55, 60, 65, 70, 75, 80, 85, 90, 95, 100,
        62, 68, 73, 78, 83, 88, 92, 97, 105, 110
    ],

    "smoke_level": [
        # NO FIRE
        0, 1, 2, 3, 4, 5, 6, 7, 3, 5,
        8, 6, 4, 2, 1, 5, 9, 7, 4, 6,

        # FIRE
        40, 45, 50, 55, 60, 65, 70, 75, 80, 85,
        48, 58, 63, 68, 73, 78, 82, 88, 92, 98
    ],

    "humidity": [
        # NO FIRE
        80, 78, 75, 72, 70, 68, 65, 63, 74, 69,
        61, 66, 71, 76, 79, 73, 60, 64, 67, 70,

        # FIRE
        45, 42, 38, 35, 32, 28, 25, 22, 18, 15,
        40, 36, 33, 30, 27, 24, 20, 17, 14, 10
    ],

    "wind_speed": [
        # NO FIRE
        1, 2, 3, 2, 4, 3, 5, 4, 2, 3,
        6, 5, 4, 2, 3, 4, 5, 3, 6, 2,

        # FIRE
        5, 6, 7, 8, 9, 10, 11, 12, 13, 14,
        6, 8, 9, 10, 11, 12, 13, 14, 15, 16
    ],

    "mq2": [
        # NO FIRE
        50, 55, 60, 65, 70, 75, 80, 85, 60, 70,
        90, 75, 65, 55, 50, 68, 85, 80, 62, 72,

        # FIRE
        250, 300, 350, 400, 450, 500, 550, 600, 650, 700,
        320, 380, 430, 480, 530, 580, 630, 680, 750, 800
    ],

    "mq7": [
        # NO FIRE
        20, 25, 30, 35, 40, 45, 50, 55, 30, 40,
        60, 50, 35, 25, 30, 45, 55, 48, 38, 42,

        # FIRE
        150, 180, 220, 260, 300, 350, 400, 450, 500, 550,
        200, 240, 280, 320, 360, 410, 460, 510, 570, 620
    ],

    "infrared_temperature": [
        # NO FIRE
        21, 23, 25, 26, 28, 29, 31, 32, 27, 30,
        33, 34, 31, 28, 26, 24, 36, 35, 32, 29,

        # FIRE
        60, 65, 70, 75, 80, 85, 90, 95, 100, 110,
        68, 73, 78, 83, 88, 93, 98, 103, 115, 120
    ],

    "flame_detected": [
        # NO FIRE
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,

        # FIRE
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1
    ],

    "fire": [
        # NO FIRE
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,

        # FIRE
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1
    ]
}


# ============================================================
# CREATE DATAFRAME
# ============================================================

df = pd.DataFrame(data)


features = [
    "temperature",
    "smoke_level",
    "humidity",
    "wind_speed",
    "mq2",
    "mq7",
    "infrared_temperature",
    "flame_detected"
]

X = df[features]
y = df["fire"]


# ============================================================
# TRAIN / TEST SPLIT
# ============================================================

X_train, X_test, y_train, y_test = train_test_split(
    X,
    y,
    test_size=0.25,
    random_state=42,
    stratify=y
)


# ============================================================
# RANDOM FOREST MODEL
# ============================================================

model = RandomForestClassifier(
    n_estimators=300,
    max_depth=8,
    random_state=42,
    class_weight="balanced"
)


model.fit(X_train, y_train)


# ============================================================
# MODEL EVALUATION
# ============================================================

predictions = model.predict(X_test)

accuracy = accuracy_score(y_test, predictions)

print("=" * 70)
print("FIREGUARD AI MODEL TRAINING COMPLETE")
print("=" * 70)

print(f"Training samples: {len(X_train)}")
print(f"Testing samples:  {len(X_test)}")
print(f"Accuracy: {accuracy * 100:.2f}%")

print()
print("Classification Report:")
print(classification_report(
    y_test,
    predictions,
    target_names=["NO FIRE", "FIRE"]
))

print("Confusion Matrix:")
print(confusion_matrix(y_test, predictions))


# ============================================================
# SAVE MODEL
# ============================================================

model_path = os.path.join(
    os.path.dirname(__file__),
    "fire_model.pkl"
)

joblib.dump(model, model_path)


print()
print(f"Model saved to: {model_path}")
print("=" * 70)