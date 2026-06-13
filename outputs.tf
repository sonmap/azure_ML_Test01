output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "location" {
  value = azurerm_resource_group.this.location
}

output "azure_ml_workspace_name" {
  value = azurerm_machine_learning_workspace.this.name
}

output "azure_ml_workspace_id" {
  value = azurerm_machine_learning_workspace.this.id
}

output "compute_instance_name" {
  value = var.enable_compute_instance ? azurerm_machine_learning_compute_instance.dev[0].name : null
}

output "cpu_cluster_name" {
  value = var.enable_cpu_cluster ? azurerm_machine_learning_compute_cluster.cpu[0].name : null
}

output "storage_account_name" {
  value = azurerm_storage_account.this.name
}

output "insurance_data_container" {
  value = azurerm_storage_container.insurance_data.name
}

output "ml_outputs_container" {
  value = azurerm_storage_container.ml_outputs.name
}

output "key_vault_name" {
  value = azurerm_key_vault.this.name
}

output "application_insights_name" {
  value = azurerm_application_insights.this.name
}

output "container_registry_name" {
  value = var.enable_container_registry ? azurerm_container_registry.this[0].name : null
}

output "next_steps" {
  value = <<EOT
1) Azure ML Studio 접속: https://ml.azure.com
2) Workspace: ${azurerm_machine_learning_workspace.this.name}
3) Kaggle CSV를 Storage container '${azurerm_storage_container.insurance_data.name}' 또는 Azure ML Data Asset으로 등록
4) aml-jobs 폴더의 sample job/pipeline을 az ml CLI로 실행
EOT
}
