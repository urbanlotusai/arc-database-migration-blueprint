# =============================================================================
# 05-db - HIPAA Compliance Profile
# =============================================================================
# Compliance controls enabled:
#   - backup_retention_period = 35 — supports the HIPAA Security Rule's data
#     backup/disaster-recovery requirements (45 CFR 164.308(a)(7)) for PHI
#     migrated into the target Aurora cluster.
#   - deletion_protection = true — guards against accidental loss of PHI
#     records that must be retrievable for the required retention period.
# =============================================================================

backup_retention_period = 35
deletion_protection     = true
