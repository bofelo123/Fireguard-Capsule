from datetime import datetime

from database import SessionLocal
from models import FireIncident


db = SessionLocal()

fire = FireIncident(
    incident_code="FIRE-001",
    title="Gaborone Wildfire",
    latitude=-24.6282,
    longitude=25.9231,
    severity="critical",
    status="active",
    detection_time=datetime.now(),
)

db.add(fire)
db.commit()

print("Fire incident added successfully.")

db.close()