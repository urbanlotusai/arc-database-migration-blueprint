# =============================================================================
# 05-db - General Compliance Profile
# =============================================================================
# Standard target Aurora cluster. 7-day backup retention and no deletion
# protection keep dev/test costs and friction low; encryption at rest is
# still always on via the CMK from 01-kms regardless of profile.
# =============================================================================

backup_retention_period = 7
deletion_protection     = false
