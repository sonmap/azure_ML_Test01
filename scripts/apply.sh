#!/usr/bin/env bash
set -euo pipefail

cp -n terraform.tfvars.example terraform.tfvars || true
terraform init
terraform plan -out tfplan
terraform apply tfplan
