# =============================================================================
# 01-kms - PCI-DSS Compliance Profile
# =============================================================================
# PCI DSS Req 3.6 requires documented key-management procedures but does not
# mandate a specific deletion window. 30 days (the AWS maximum) is kept for
# the same reason as the HIPAA profile: it maximizes the recovery window
# before cardholder-data encryption keys (protecting the target Aurora
# cluster and DMS logs) are unrecoverably destroyed.
# =============================================================================

deletion_window_in_days = 30
