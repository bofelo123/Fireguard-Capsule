from database import SessionLocal
from models import Capsule
from device_security import generate_device_token, hash_device_token

CAPSULE_CODE = "FG-CAP-001"

db = SessionLocal()

try:
    capsule = (
        db.query(Capsule)
        .filter(Capsule.capsule_code == CAPSULE_CODE)
        .first()
    )

    if capsule is None:
        raise Exception(f"Capsule {CAPSULE_CODE} not found")

    device_token = generate_device_token()

    capsule.device_token_hash = hash_device_token(device_token)

    db.commit()

    print("CAPSULE PROVISIONED SUCCESSFULLY")
    print("Capsule:", capsule.capsule_code)
    print("Device Token:", device_token)
    print()
    print("IMPORTANT: Save this token securely.")
    print("It will be required by the physical hardware.")

finally:
    db.close()