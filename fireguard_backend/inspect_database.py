import sqlite3

connection = sqlite3.connect("fireguard.db")
cursor = connection.cursor()

# ---------------------------------------------------------
# Show all tables
# ---------------------------------------------------------
cursor.execute("""
    SELECT name
    FROM sqlite_master
    WHERE type='table'
    ORDER BY name
""")

tables = cursor.fetchall()

print("\nTables in fireguard.db:")
print("-----------------------")

for table in tables:
    print(table[0])


# ---------------------------------------------------------
# Show USERS table structure
# ---------------------------------------------------------
cursor.execute("PRAGMA table_info(users)")

user_columns = cursor.fetchall()

print("\nUsers table columns:")
print("--------------------")

for column in user_columns:
    print(
        f"Name: {column[1]} | "
        f"Type: {column[2]} | "
        f"Not Null: {column[3]} | "
        f"Primary Key: {column[5]}"
    )


# ---------------------------------------------------------
# Show users
# ---------------------------------------------------------
cursor.execute("""
    SELECT id, full_name, email
    FROM users
    ORDER BY id
""")

users = cursor.fetchall()

print("\nUsers in fireguard.db:")
print("----------------------")

for user in users:
    print(
        f"ID: {user[0]} | "
        f"Name: {user[1]} | "
        f"Email: {user[2]}"
    )


# ---------------------------------------------------------
# Show CAPSULES table structure
# ---------------------------------------------------------
cursor.execute("PRAGMA table_info(capsules)")

capsule_columns = cursor.fetchall()

print("\nCapsules table columns:")
print("-----------------------")

for column in capsule_columns:
    print(
        f"Name: {column[1]} | "
        f"Type: {column[2]} | "
        f"Not Null: {column[3]} | "
        f"Primary Key: {column[5]}"
    )


connection.close()