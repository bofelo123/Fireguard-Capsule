import hashlib
import secrets


# ============================================================
# GENERATE DEVICE TOKEN
# ============================================================

def generate_device_token() -> str:
    """
    Generate a cryptographically secure secret token
    for a FireGuard hardware capsule.
    """

    return secrets.token_urlsafe(32)


# ============================================================
# HASH DEVICE TOKEN
# ============================================================

def hash_device_token(token: str) -> str:
    """
    Convert the device token into a SHA-256 hash.

    Only this hash should be stored in the database.
    """

    return hashlib.sha256(
        token.encode("utf-8")
    ).hexdigest()


# ============================================================
# VERIFY DEVICE TOKEN
# ============================================================

def verify_device_token(
    token: str,
    stored_hash: str,
) -> bool:
    """
    Verify a device token against the hash stored
    in the database.
    """

    calculated_hash = hash_device_token(token)

    return secrets.compare_digest(
        calculated_hash,
        stored_hash,
    )