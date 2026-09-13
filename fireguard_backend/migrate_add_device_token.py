import sqlite3


DATABASE_FILE = "fireguard.db"


print("Starting database migration...")


connection = sqlite3.connect(DATABASE_FILE)

cursor = connection.cursor()


# ============================================================
# CHECK EXISTING CAPSULE COLUMNS
# ============================================================

cursor.execute("PRAGMA table_info(capsules)")

columns = cursor.fetchall()

column_names = {
    column[1]
    for column in columns
}


# ============================================================
# ADD DEVICE TOKEN HASH
# ============================================================

if "device_token_hash" not in column_names:

    print("Adding device_token_hash column...")

    cursor.execute(
        """
        ALTER TABLE capsules
        ADD COLUMN device_token_hash VARCHAR
        """
    )

    print("device_token_hash column added.")

else:

    print("device_token_hash column already exists.")


# ============================================================
# CREATE UNIQUE INDEX
# ============================================================

cursor.execute(
    """
    CREATE UNIQUE INDEX IF NOT EXISTS
    ix_capsules_device_token_hash
    ON capsules(device_token_hash)
    """
)

print("Unique device token index verified.")


# ============================================================
# SAVE CHANGES
# ============================================================

connection.commit()

connection.close()


print("Database migration completed successfully.")