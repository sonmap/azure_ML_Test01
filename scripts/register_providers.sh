#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   az login
#   az account set --subscription <SUBSCRIPTION_ID>
#   ./scripts/register_providers.sh

providers=(
  Microsoft.MachineLearningServices
  Microsoft.Storage
  Microsoft.KeyVault
  Microsoft.Insights
  Microsoft.ContainerRegistry
  Microsoft.Notebooks
  Microsoft.Authorization
)

for p in "${providers[@]}"; do
  echo "Registering $p ..."
  az provider register --namespace "$p" --wait
  az provider show --namespace "$p" --query "{namespace:namespace, registrationState:registrationState}" -o table
  echo
 done
