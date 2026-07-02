#!/bin/bash
# =============================================================================
# Helper script to apply a single module with optional compliance profile
# Usage: ./scripts/apply-module.sh <module-name> [environment] [region] [compliance-profile]
# Examples:
#   ./scripts/apply-module.sh 01-kms dev us-east-1 general
#   ./scripts/apply-module.sh 05-db dev us-east-1 hipaa
#   ./scripts/apply-module.sh 06-dms dev us-east-1 pci
# =============================================================================

set -e

MODULE_NAME="${1:-}"
ENVIRONMENT="${2:-dev}"
REGION="${3:-us-east-1}"
COMPLIANCE_PROFILE="${4:-general}"
NAMESPACE="${NAMESPACE:-arc}"
STATE_BUCKET="${NAMESPACE}-${ENVIRONMENT}-terraform-state"
LOCK_TABLE="${NAMESPACE}-${ENVIRONMENT}-terraform-locks"

if [[ -z "$MODULE_NAME" ]]; then
  echo "Usage: ./scripts/apply-module.sh <module-name> [environment] [region] [compliance-profile]"
  echo "Example: ./scripts/apply-module.sh 01-kms dev us-east-1 general"
  echo ""
  echo "Compliance profiles: general (default), hipaa, pci"
  exit 1
fi

echo "========================================"
echo "Applying module:   $MODULE_NAME"
echo "Environment:       $ENVIRONMENT"
echo "Region:            $REGION"
echo "Compliance:        $COMPLIANCE_PROFILE"
echo "State bucket:      $STATE_BUCKET"
echo "Lock table:        $LOCK_TABLE"
echo "========================================"

# Find module directory
MODULE_DIR=""
for dir in modules/*/; do
  if [[ "$(basename "$dir")" == *"$MODULE_NAME"* ]]; then
    MODULE_DIR="$dir"
    break
  fi
done

if [[ -z "$MODULE_DIR" ]]; then
  echo "Error: Module directory not found for: $MODULE_NAME"
  echo "Available modules:"
  ls modules/
  exit 1
fi

echo "Module directory: $MODULE_DIR"
cd "$MODULE_DIR"

# Copy compliance profile tfvars -> terraform.tfvars (auto-loaded by Terraform)
TFVARS_FILE="tfvars/${COMPLIANCE_PROFILE}.tfvars"
if [[ -f "$TFVARS_FILE" ]]; then
  echo "Using compliance profile: $TFVARS_FILE"
  cp "$TFVARS_FILE" terraform.tfvars
else
  echo "Note: No $TFVARS_FILE found (normal for some modules)"
  rm -f terraform.tfvars
fi

# Initialise with static config.hcl (key only) + dynamic backend values
echo "Initializing Terraform..."
terraform init -reconfigure \
  -backend-config=config.hcl \
  -backend-config="bucket=${STATE_BUCKET}" \
  -backend-config="dynamodb_table=${LOCK_TABLE}" \
  -backend-config="region=${REGION}"

# Plan - namespace/environment/region/state_bucket_name override any stale
# values that might have slipped into terraform.tfvars
echo "Running Terraform plan..."
terraform plan \
  -var="namespace=${NAMESPACE}" \
  -var="environment=${ENVIRONMENT}" \
  -var="region=${REGION}" \
  -var="state_bucket_name=${STATE_BUCKET}"

# Apply
echo "Running Terraform apply..."
terraform apply -auto-approve \
  -var="namespace=${NAMESPACE}" \
  -var="environment=${ENVIRONMENT}" \
  -var="region=${REGION}" \
  -var="state_bucket_name=${STATE_BUCKET}"

echo "========================================"
echo "Module $MODULE_NAME applied successfully!"
echo "========================================"
