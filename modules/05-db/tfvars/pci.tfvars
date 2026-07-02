# =============================================================================
# 05-db - PCI-DSS Compliance Profile
# =============================================================================
# Compliance controls enabled:
#   - backup_retention_period = 35 — supports PCI DSS Req 10.7's requirement
#     to retain audit trail history and Req 9.5's data-availability
#     expectations for cardholder data migrated into the target Aurora
#     cluster.
#   - deletion_protection = true — guards against accidental loss of
#     cardholder-data records that must remain available for the required
#     retention period.
# =============================================================================

backup_retention_period = 35
deletion_protection     = true
