data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
}

locals {
  normalized_prefix = lower(replace(var.name_prefix, "/[^0-9A-Za-z-]/", ""))
  compact_prefix    = substr(lower(replace(var.name_prefix, "/[^0-9A-Za-z]/", "")), 0, 10)

  suffix        = random_string.suffix.result
  developer_oid = var.developer_object_id != "" ? var.developer_object_id : data.azurerm_client_config.current.object_id

  common_tags = merge({
    workload    = "insurance-mlops"
    environment = var.environment
    managed_by  = "terraform"
    purpose     = "kaggle-motor-insurance-mlops-test"
  }, var.tags)
}
