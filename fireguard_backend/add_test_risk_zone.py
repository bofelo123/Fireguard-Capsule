from database import SessionLocal
from models import RiskZone

db = SessionLocal()

risk_zone = RiskZone(
    zone_code="ZONE-001",
    risk_score=85.0,
    polygon_json='[[-24.6200,25.9150],[-24.6200,25.9350],[-24.6350,25.9350],[-24.6350,25.9150]]'
)

db.add(risk_zone)
db.commit()
db.refresh(risk_zone)

print("Risk zone created successfully")
print("ID:", risk_zone.id)
print("Zone Code:", risk_zone.zone_code)
print("Risk Score:", risk_zone.risk_score)
print("Polygon:", risk_zone.polygon_json)

db.close()