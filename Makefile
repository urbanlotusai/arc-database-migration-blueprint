.PHONY: help init plan apply validate fmt bootstrap verify-sample

# Default target
help:
	@echo "Arc Database Migration Blueprint - Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make init          Initialize all modules (requires bootstrap first)"
	@echo "  make plan          Run terraform plan on all modules"
	@echo "  make apply         Apply all modules in order"
	@echo "  make validate      Validate all Terraform configurations"
	@echo "  make fmt           Format all Terraform files"
	@echo "  make bootstrap     Apply bootstrap module (creates state backend)"
	@echo "  make verify-sample Run the sample-app schema verification script"
	@echo ""
	@echo "Variables:"
	@echo "  ENV=dev            Environment (default: dev)"
	@echo "  REGION=us-east-1   AWS region (default: us-east-1)"
	@echo "  NAMESPACE=arc      Namespace prefix (default: arc)"
	@echo "  PROFILE=general    Compliance profile (general|hipaa|pci; default: general)"

# Variables
ENV ?= dev
REGION ?= us-east-1
NAMESPACE ?= arc
STATE_BUCKET = $(NAMESPACE)-$(ENV)-terraform-state
LOCK_TABLE = $(NAMESPACE)-$(ENV)-terraform-locks

# Bootstrap module (uses local state - no config.hcl)
bootstrap:
	@echo "Applying bootstrap..."
	cd bootstrap && terraform init && terraform apply \
		-var="namespace=$(NAMESPACE)" \
		-var="environment=$(ENV)" \
		-var="region=$(REGION)"

# Initialize all modules
init: bootstrap
	@echo "Initializing modules..."
	@for dir in modules/*/; do \
		echo "Initializing $$(basename $$dir)..."; \
		cd $$dir && terraform init -reconfigure \
			-backend-config=config.hcl \
			-backend-config="bucket=$(STATE_BUCKET)" \
			-backend-config="dynamodb_table=$(LOCK_TABLE)" \
			-backend-config="region=$(REGION)" \
			|| exit 1; \
		cd - > /dev/null; \
	done

# Plan all modules
plan: init
	@echo "Planning all modules..."
	@for dir in modules/*/; do \
		echo "Planning $$(basename $$dir)..."; \
		cd $$dir && terraform plan \
			-var="state_bucket_name=$(STATE_BUCKET)" \
			-var="namespace=$(NAMESPACE)" \
			-var="environment=$(ENV)" \
			-var="region=$(REGION)" \
			|| exit 1; \
		cd - > /dev/null; \
	done

# Apply all modules in order
apply: init
	@echo "Applying all modules..."
	@for dir in modules/*/; do \
		echo "Applying $$(basename $$dir)..."; \
		cd $$dir && terraform apply -auto-approve \
			-var="state_bucket_name=$(STATE_BUCKET)" \
			-var="namespace=$(NAMESPACE)" \
			-var="environment=$(ENV)" \
			-var="region=$(REGION)" \
			|| exit 1; \
		cd - > /dev/null; \
	done

# Validate all modules
validate:
	@echo "Validating all modules..."
	@for dir in bootstrap modules/*/; do \
		echo "Validating $$(basename $$dir)..."; \
		cd $$dir && terraform validate || exit 1; \
		cd - > /dev/null; \
	done

# Format all Terraform files
fmt:
	@echo "Formatting Terraform files..."
	@find . -name "*.tf" -exec terraform fmt {} \;

# Run the sample-app schema verification script against the target Aurora cluster
verify-sample:
	@echo "Running sample-app verification..."
	@cd sample-app && ./verify.sh
