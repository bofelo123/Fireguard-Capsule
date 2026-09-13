from predictor import predict_fire


# ============================================================
# FIREGUARD AI TEST
# ============================================================

result = predict_fire(

    temperature=85,

    smoke_level=90,

    humidity=20,

    wind_speed=12,

    mq2=650,

    mq7=500,

    infrared_temperature=95,

    flame_detected=True,
)


print("=" * 70)
print("FIREGUARD AI SENSOR FUSION TEST")
print("=" * 70)

for key, value in result.items():
    print(f"{key}: {value}")

print("=" * 70)