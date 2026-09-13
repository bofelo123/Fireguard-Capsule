from database import Base, engine
from models import (
    User,
    Capsule,
    FireIncident,
    RiskZone,
    Alert,
    AlertTimelineEvent,
)


print("Creating database tables...")

# Create all tables defined in models
Base.metadata.create_all(bind=engine)

print("Database tables created successfully.")