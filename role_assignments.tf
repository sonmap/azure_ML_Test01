# Current Terraform identity convenience permissions.
# If your organization restricts role assignment creation, set these manually in Azure Portal/CLI.
resource "azurerm_role_assignment" "current_user_storage_blob_data_contributor" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "current_user_key_vault_secrets_officer" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "current_user_aml_data_scientist" {
  scope                = azurerm_machine_learning_workspace.this.id
  role_definition_name = "AzureML Data Scientist"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Workspace managed identity access to backing services.
resource "azurerm_role_assignment" "workspace_storage_blob_data_contributor" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_machine_learning_workspace.this.identity[0].principal_id
}

resource "azurerm_role_assignment" "workspace_key_vault_secrets_user" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_machine_learning_workspace.this.identity[0].principal_id
}

resource "azurerm_role_assignment" "workspace_acr_pull" {
  count                = var.enable_container_registry ? 1 : 0
  scope                = azurerm_container_registry.this[0].id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_machine_learning_workspace.this.identity[0].principal_id
}
