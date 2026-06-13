resource "azurerm_resource_group" "this" {
  name     = "rg-${local.normalized_prefix}-${var.environment}-${var.location_short}"
  location = var.location
  tags     = local.common_tags
}
