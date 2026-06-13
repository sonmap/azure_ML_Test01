resource "azurerm_machine_learning_compute_instance" "dev" {
  count = var.enable_compute_instance ? 1 : 0
  name  = var.compute_instance_name
  #location                      = azurerm_resource_group.this.location
  machine_learning_workspace_id = azurerm_machine_learning_workspace.this.id
  virtual_machine_size          = var.compute_instance_vm_size
  authorization_type            = "personal"
  local_auth_enabled            = false
  node_public_ip_enabled        = true
  description                   = "Notebook development compute for Kaggle motor insurance analysis. Stop it when idle to reduce cost."

  assign_to_user {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = local.developer_oid
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

resource "azurerm_machine_learning_compute_cluster" "cpu" {
  count                         = var.enable_cpu_cluster ? 1 : 0
  name                          = var.cpu_cluster_name
  location                      = azurerm_resource_group.this.location
  machine_learning_workspace_id = azurerm_machine_learning_workspace.this.id
  vm_size                       = var.cpu_cluster_vm_size
  vm_priority                   = var.cpu_cluster_vm_priority
  local_auth_enabled            = false
  ssh_public_access_enabled     = false

  scale_settings {
    min_node_count                       = var.cpu_cluster_min_nodes
    max_node_count                       = var.cpu_cluster_max_nodes
    scale_down_nodes_after_idle_duration = var.cpu_cluster_idle_duration
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}
