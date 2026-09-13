import pandas as pd
import os

# ============================================================
# FIREGUARD NASA FIRMS DATA PREPARATION
# ============================================================

INPUT_FILE = os.path.join(
    os.path.dirname(__file__),
    "data",
    "J1_VIIRS_C2_Southern_Africa_7d.csv"
)

OUTPUT_FILE = os.path.join(
    os.path.dirname(__file__),
    "data",
    "nasa_fire_events.csv"
)


# ============================================================
# LOAD NASA DATA
# ============================================================

print("=" * 70)
print("FIREGUARD NASA FIRMS DATA PREPARATION")
print("=" * 70)

print("\nLoading NASA FIRMS dataset...")

df = pd.read_csv(INPUT_FILE)

print(f"Loaded records: {len(df):,}")


# ============================================================
# SELECT RELEVANT REAL NASA FEATURES
# ============================================================

columns = [
    "latitude",
    "longitude",
    "bright_ti4",
    "scan",
    "track",
    "acq_date",
    "acq_time",
    "satellite",
    "confidence",
    "version",
    "bright_ti5",
    "frp",
    "daynight"
]

df = df[columns].copy()


# ============================================================
# CLEAN DATA
# ============================================================

df["acq_date"] = pd.to_datetime(
    df["acq_date"],
    errors="coerce"
)

df["acq_time"] = pd.to_numeric(
    df["acq_time"],
    errors="coerce"
)

numeric_columns = [
    "latitude",
    "longitude",
    "bright_ti4",
    "scan",
    "track",
    "acq_time",
    "bright_ti5",
    "frp"
]

for column in numeric_columns:
    df[column] = pd.to_numeric(
        df[column],
        errors="coerce"
    )


# ============================================================
# REMOVE INVALID RECORDS
# ============================================================

before = len(df)

df = df.dropna()

after = len(df)

print(f"\nRecords before cleaning: {before:,}")
print(f"Records after cleaning:  {after:,}")
print(f"Records removed:         {before - after:,}")


# ============================================================
# REMOVE DUPLICATES
# ============================================================

before_duplicates = len(df)

df = df.drop_duplicates()

after_duplicates = len(df)

print(f"\nDuplicates removed: {before_duplicates - after_duplicates:,}")


# ============================================================
# CREATE FIRE EVENT LABEL
# ============================================================
#
# IMPORTANT:
# NASA FIRMS records represent detected fire events.
# Therefore this label is NOT claiming that all other
# locations are "NO FIRE".
#
# fire_event = 1 means NASA FIRMS detected a fire event.
# ============================================================

df["fire_event"] = 1


# ============================================================
# SAVE PREPARED DATASET
# ============================================================

df.to_csv(
    OUTPUT_FILE,
    index=False
)


# ============================================================
# SUMMARY
# ============================================================

print("\n---------- Prepared Dataset ----------")

print(f"Records: {len(df):,}")
print(f"Columns: {len(df.columns)}")

print("\nColumns:")

for column in df.columns:
    print(f"  - {column}")

print("\nDate range:")

print(
    f"  {df['acq_date'].min().date()} "
    f"to "
    f"{df['acq_date'].max().date()}"
)

print("\nFire-event labels:")

print(df["fire_event"].value_counts())

print("\nSaved to:")

print(OUTPUT_FILE)

print("\n" + "=" * 70)
print("NASA DATA PREPARATION COMPLETE")
print("=" * 70)