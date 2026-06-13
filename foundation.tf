resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-${local.normalized_prefix}-${var.environment}-${var.location_short}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.common_tags
}

resource "azurerm_application_insights" "this" {
  name                = "appi-${local.normalized_prefix}-${var.environment}-${var.location_short}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  workspace_id        = azurerm_log_analytics_workspace.this.id
  application_type    = "web"
  tags                = local.common_tags
}

resource "azurerm_key_vault" "this" {
  name                = "kv-${substr(local.compact_prefix, 0, 8)}-${local.suffix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  #enable_rbac_authorization     = true
  rbac_authorization_enabled    = true
  purge_protection_enabled      = false
  soft_delete_retention_days    = 7
  public_network_access_enabled = true
  tags                          = local.common_tags
}

resource "azurerm_storage_account" "this" {
  name                            = "st${substr(local.compact_prefix, 0, 10)}${local.suffix}"
  location                        = azurerm_resource_group.this.location
  resource_group_name             = azurerm_resource_group.this.name
  account_tier                    = "Standard"
  account_replication_type        = var.storage_replication_type
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = true
  shared_access_key_enabled       = true
  tags                            = local.common_tags
}

resource "azurerm_storage_container" "insurance_data" {
  name                  = "insurance-data"
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "ml_outputs" {
  name                  = "ml-outputs"
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}

resource "azurerm_container_registry" "this" {
  count               = var.enable_container_registry ? 1 : 0
  name                = "acr${substr(local.compact_prefix, 0, 10)}${local.suffix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = var.container_registry_sku
  admin_enabled       = false
  tags                = local.common_tags
}
