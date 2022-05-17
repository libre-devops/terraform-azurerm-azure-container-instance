resource "azurerm_network_profile" "net_prof" {
  count               = var.vnet_integration_enabled && var.os_type == "Linux" ? 1 : 0
  location            = var.location
  name                = var.network_profile_name
  resource_group_name = var.rg_name
  tags                = var.tags

  dynamic "container_network_interface" {
    for_each = var.vnet_integration_enabled == true && var.os_type == "Linux" && lookup(var.settings, "container_network_interface", {}) != {} ? [1] : []

    content {
      name = lookup(var.settings.container_network_interface, "username", null)

      dynamic "ip_configuration" {
        for_each = var.vnet_integration_enabled == true && var.os_type == "Linux" && lookup(var.settings.container_network_interface, "ip_configuration", {}) != {} ? [1] : []

        content {
          name      = lookup(var.settings.container_network_interface.ip_configuration, "name", null)
          subnet_id = lookup(var.settings.container_network_interface.ip_configuration, "subnet_id", null)
        }
      }
    }
  }
}
