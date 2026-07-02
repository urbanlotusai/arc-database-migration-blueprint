# =============================================================================
# 06-dms - General Compliance Profile
# =============================================================================
# No profile-specific overrides — dms_multi_az and migration_type are
# operator/architecture choices (HA and cutover strategy), not compliance
# controls driven by this blueprint's compliance profile. Encryption at
# rest/in-transit (KMS CMK, SSL endpoints) is always on regardless of
# profile. Source connection details still need to be supplied here or via
# -var overrides before apply.
# =============================================================================
