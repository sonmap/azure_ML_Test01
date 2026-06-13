resource "azurerm_machine_learning_workspace" "this" {
  name                    = "mlw-${local.normalized_prefix}-${var.environment}-${var.location_short}"
  location                = azurerm_resource_group.this.location
  resource_group_name     = azurerm_resource_group.this.name
  application_insights_id = azurerm_application_insights.this.id
  key_vault_id            = azurerm_key_vault.this.id
  storage_account_id      = azurerm_storage_account.this.id
  container_registry_id   = var.enable_container_registry ? azurerm_container_registry.this[0].id : null

  public_network_access_enabled = true

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}
