import pandas as pd

file_path = "ai/data/J1_VIIRS_C2_Southern_Africa_7d.csv"

df = pd.read_csv(file_path)

print("\n========== NASA FIRMS DATASET ==========")

print(f"\nRows: {len(df):,}")
print(f"Columns: {len(df.columns)}")

print("\n---------- Columns ----------")
for column in df.columns:
    print(column)

print("\n---------- Missing Values ----------")
print(df.isna().sum())

print("\n---------- Data Types ----------")
print(df.dtypes)

print("\n---------- First 5 Records ----------")
print(df.head())

print("\n---------- Numerical Summary ----------")
print(df.describe())

print("\n========== END ==========")