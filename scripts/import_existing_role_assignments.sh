#!/usr/bin/env bash
set -euo pipefail

# import_existing_role_assignments.sh
# 목적:
# - Azure에 이미 생성되어 있는 Role Assignment를 찾아 Terraform state에 자동 import
# - RoleAssignmentExists 409 오류 대응용
#
# 사용 예:
#   chmod +x scripts/import_existing_role_assignments.sh
#   ./scripts/import_existing_role_assignments.sh
#
# 필요 도구:
#   az, terraform
#
# 필요 권한:
#   role assignment 조회 권한
#   Terraform state 수정 권한

log() {
  echo "[INFO] $*"
}

warn() {
  echo "[WARN] $*" >&2
}

err() {
  echo "[ERROR] $*" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || err "$1 명령어가 없습니다."
}

tf_output() {
  local name="$1"
  terraform output -raw "$name" 2>/dev/null || true
}

state_exists() {
  local addr="$1"
  terraform state show "$addr" >/dev/null 2>&1
}

import_if_exists() {
  local addr="$1"
  local scope="$2"
  local principal_id="$3"
  local role_name="$4"

  if [[ -z "$scope" || -z "$principal_id" || -z "$role_name" ]]; then
    warn "필수값 누락으로 skip: addr=$addr scope=$scope principal_id=$principal_id role=$role_name"
    return 0
  fi

  if state_exists "$addr"; then
    log "이미 Terraform state에 있음: $addr"
    return 0
  fi

  log "Azure Role Assignment 조회: role='$role_name', principal='$principal_id'"
  log "scope=$scope"

  local role_assignment_id
  role_assignment_id=$(az role assignment list \
    --scope "$scope" \
    --query "[?principalId=='${principal_id}' && roleDefinitionName=='${role_name}'].id | [0]" \
    -o tsv 2>/dev/null || true)

  if [[ -z "$role_assignment_id" || "$role_assignment_id" == "None" ]]; then
    warn "Azure에 기존 Role Assignment 없음. import skip: $addr / $role_name"
    return 0
  fi

  log "import 실행: $addr"
  terraform import "$addr" "$role_assignment_id"
}

need_cmd az
need_cmd terraform

# -------------------------------------------------------------------
# 1) 기본값 읽기
# -------------------------------------------------------------------
SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-$(az account show --query id -o tsv 2>/dev/null || true)}"
[[ -n "$SUBSCRIPTION_ID" ]] || err "Azure subscription을 확인할 수 없습니다. az login / az account set 확인 필요"

# Terraform output이 있으면 우선 사용하고, 없으면 현재 테스트 기본 이름 사용
RG="${RG:-$(tf_output resource_group_name)}"
WS="${WS:-$(tf_output azure_ml_workspace_name)}"
STORAGE_ACCOUNT="${STORAGE_ACCOUNT:-$(tf_output storage_account_name)}"
KEYVAULT_NAME="${KEYVAULT_NAME:-$(tf_output key_vault_name)}"
ACR_NAME="${ACR_NAME:-$(tf_output container_registry_name)}"

# output이 비어 있으면 현재 사용 중인 기본값으로 fallback
RG="${RG:-rg-ins-mlops-dev-krc}"
WS="${WS:-mlw-ins-mlops-dev-krc}"
STORAGE_ACCOUNT="${STORAGE_ACCOUNT:-stinsmlops6n1381}"
KEYVAULT_NAME="${KEYVAULT_NAME:-kv-insmlops-6n1381}"
ACR_NAME="${ACR_NAME:-acrinsmlops6n1381}"

log "SUBSCRIPTION_ID=$SUBSCRIPTION_ID"
log "RG=$RG"
log "WS=$WS"
log "STORAGE_ACCOUNT=$STORAGE_ACCOUNT"
log "KEYVAULT_NAME=$KEYVAULT_NAME"
log "ACR_NAME=$ACR_NAME"

# -------------------------------------------------------------------
# 2) 리소스 ID 조회
# -------------------------------------------------------------------
STORAGE_ID=$(az storage account show \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RG" \
  --query id -o tsv 2>/dev/null || true)

KV_ID=$(az keyvault show \
  --name "$KEYVAULT_NAME" \
  --resource-group "$RG" \
  --query id -o tsv 2>/dev/null || true)

ACR_ID=$(az acr show \
  --name "$ACR_NAME" \
  --resource-group "$RG" \
  --query id -o tsv 2>/dev/null || true)

WORKSPACE_ID="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG}/providers/Microsoft.MachineLearningServices/workspaces/${WS}"

if [[ -z "$STORAGE_ID" ]]; then
  warn "Storage Account를 찾지 못했습니다: $STORAGE_ACCOUNT"
fi

if [[ -z "$KV_ID" ]]; then
  warn "Key Vault를 찾지 못했습니다: $KEYVAULT_NAME"
fi

if [[ -z "$ACR_ID" ]]; then
  warn "ACR를 찾지 못했습니다: $ACR_NAME"
fi

# -------------------------------------------------------------------
# 3) Principal ID 조회
# -------------------------------------------------------------------
CURRENT_USER_OBJECT_ID="${CURRENT_USER_OBJECT_ID:-$(az ad signed-in-user show --query id -o tsv 2>/dev/null || true)}"

# az ml이 안 되거나 출력 구조가 다를 수 있어 az resource show로 조회
WORKSPACE_PRINCIPAL_ID=$(az resource show \
  --ids "$WORKSPACE_ID" \
  --query "identity.principalId" \
  -o tsv 2>/dev/null || true)

if [[ -z "$WORKSPACE_PRINCIPAL_ID" || "$WORKSPACE_PRINCIPAL_ID" == "null" ]]; then
  WORKSPACE_PRINCIPAL_ID=$(az ml workspace show \
    --name "$WS" \
    --resource-group "$RG" \
    --query "identity.principal_id" \
    -o tsv 2>/dev/null || true)
fi

log "CURRENT_USER_OBJECT_ID=${CURRENT_USER_OBJECT_ID:-N/A}"
log "WORKSPACE_PRINCIPAL_ID=${WORKSPACE_PRINCIPAL_ID:-N/A}"

# -------------------------------------------------------------------
# 4) Terraform Role Assignment 자동 import
# -------------------------------------------------------------------

# 현재 사용자 → Storage Blob Data Contributor
if [[ -n "${CURRENT_USER_OBJECT_ID:-}" && -n "${STORAGE_ID:-}" ]]; then
  import_if_exists \
    "azurerm_role_assignment.current_user_storage_blob_data_contributor" \
    "$STORAGE_ID" \
    "$CURRENT_USER_OBJECT_ID" \
    "Storage Blob Data Contributor"
fi

# 현재 사용자 → AzureML Data Scientist
if [[ -n "${CURRENT_USER_OBJECT_ID:-}" ]]; then
  import_if_exists \
    "azurerm_role_assignment.current_user_aml_data_scientist" \
    "$WORKSPACE_ID" \
    "$CURRENT_USER_OBJECT_ID" \
    "AzureML Data Scientist"
fi

# Azure ML Workspace Managed Identity → Storage Blob Data Contributor
if [[ -n "${WORKSPACE_PRINCIPAL_ID:-}" && -n "${STORAGE_ID:-}" ]]; then
  import_if_exists \
    "azurerm_role_assignment.workspace_storage_blob_data_contributor" \
    "$STORAGE_ID" \
    "$WORKSPACE_PRINCIPAL_ID" \
    "Storage Blob Data Contributor"
fi

# Azure ML Workspace Managed Identity → Key Vault Secrets User
if [[ -n "${WORKSPACE_PRINCIPAL_ID:-}" && -n "${KV_ID:-}" ]]; then
  import_if_exists \
    "azurerm_role_assignment.workspace_key_vault_secrets_user" \
    "$KV_ID" \
    "$WORKSPACE_PRINCIPAL_ID" \
    "Key Vault Secrets User"
fi

# Azure ML Workspace Managed Identity → AcrPull
# Terraform 리소스가 count를 사용할 경우 주소는 workspace_acr_pull[0]
if [[ -n "${WORKSPACE_PRINCIPAL_ID:-}" && -n "${ACR_ID:-}" ]]; then
  import_if_exists \
    "azurerm_role_assignment.workspace_acr_pull[0]" \
    "$ACR_ID" \
    "$WORKSPACE_PRINCIPAL_ID" \
    "AcrPull"
fi

log "Role Assignment import 점검 완료"
log "다음 명령 실행:"
echo "terraform plan -out tfplan"
echo "terraform apply tfplan"

