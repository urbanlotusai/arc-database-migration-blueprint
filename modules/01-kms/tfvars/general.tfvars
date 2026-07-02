# =============================================================================
# 01-kms - General Compliance Profile
# =============================================================================
# Standard customer-managed key with a 30-day deletion window. No compliance
# controls are profile-specific for this module — see hipaa.tfvars / pci.tfvars
# for why the deletion window stays the same across all profiles.
# =============================================================================

deletion_window_in_days = 30
