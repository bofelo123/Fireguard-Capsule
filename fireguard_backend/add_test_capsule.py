from database import SessionLocal
from models import Capsule
from datetime import datetime


db = SessionLocal()

capsule = Capsule(
    capsule_code="CAP-001",
    name="FireGuard Capsule 001",
    location_name="Gaborone",
    latitude=-24.6282,
    longitude=25.9231,
    status="online",
    is_active=True,
    battery_level=87.5,
    solar_status="charging",
    communication_status="connected",
    sensor_status="normal",
    last_communication=datetime.now(),
    owner_id=2,
)

db.add(capsule)
db.commit()
db.refresh(capsule)

print("Capsule created successfully")
print("ID:", capsule.id)
print("Code:", capsule.capsule_code)

db.close()