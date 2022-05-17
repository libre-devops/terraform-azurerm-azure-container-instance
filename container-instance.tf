resource "azurerm_container_group" "aci" {
  name = var.container_instance_name

  location            = var.location
  resource_group_name = var.rg_name

  ## review this
  ip_address_type    = var.vnet_integration_enabled || var.os_type == "Windows" ? var.ip_address_type : null
  network_profile_id = var.vnet_integration_enabled || var.os_type == "Windows" ? azurerm_network_profile.network_profile["enabled"].id : null
  dns_name_label     = var.vnet_integration_enabled || var.os_type == "Windows" ? null : coalesce(var.dns_name_label, var.aci_name)

  os_type = title(var.os_type)

  restart_policy = var.restart_policy

  key_vault_key_id  = var.key_vault_key_id


  dynamic "identity" {
    for_each = length(var.identity_ids) == 0 && var.identity_type == "SystemAssigned" ? [var.identity_type] : []
    content {
      type = var.identity_type
    }
  }

  dynamic "identity" {
    for_each = length(var.identity_ids) > 0 || var.identity_type == "UserAssigned" ? [var.identity_type] : []
    content {
      type         = var.identity_type
      identity_ids = length(var.identity_ids) > 0 ? var.identity_ids : []
    }
  }

  dynamic "exposed_port" {
    for_each = lookup(var.settings, "exposed_port", {}) != {} ? [1] : []

    content {
      username = lookup(var.settings.exposed_port, "port", null)
      protocol = lookup(var.settings.exposed_port, "protocol", null)
    }
  }

  dynamic "image_registry_credential" {
    for_each = lookup(var.settings, "image_registry_credential", {}) != {} ? [1] : []

    content {
      username = lookup(var.settings.image_registry_credential, "username", null)
      password = lookup(var.settings.image_registry_credential, "password", null)
      server   = lookup(var.settings.image_registry_credential, "login_server", null)
    }
  }

  dynamic "dns_config" {
    for_each = lookup(var.settings, "dns_config", {}) != {} ? [1] : []

    content {
      nameservers = tolist(lookup(var.settings.dns_config, "nameservers", null))
      search_domains = tolist(lookup(var.settings.dns_config, "search_domains", null))
      options   = tolist(lookup(var.settings.dns_config, "options", null))
    }
  }

    dynamic "diagnostics" {
    for_each = lookup(var.settings, "diagnostics", {}) != {} ? [1] : []

    content {
      dynamic "log_analytics" {
        for_each = lookup(var.settings.diagnostics, "log_analytics", {}) != {} ? [1] : []
        content {
          workspace_id  = lookup(var.settings.diagnostics.log_analytics, "workspace_id", null)
          workspace_key = lookup(var.settings.diagnostics.log_analytics, "workspace_key", null)
        }
      }
    }
  }

  dynamic "container" {
    for_each = lookup(var.settings, "container", {}) != {} ? [1] : []

    content {
      name = container.key

      image  = container.value.image
      cpu    = container.value.cpu
      memory = container.value.memory

      environment_variables        = lookup(container.value, "environment_variables", null)
      secure_environment_variables = lookup(container.value, "secure_environment_variables", null)
      commands                     = lookup(container.value, "commands", null)

      dynamic "ports" {
        for_each = container.value.ports

        content {
          port     = ports.value.port
          protocol = ports.value.protocol
        }
      }
    }
  }

    dynamic "init_container" {
    for_each = var.containers_config

    content {
      name = container.key

      image  = container.value.image
      cpu    = container.value.cpu
      memory = container.value.memory

      environment_variables        = lookup(container.value, "environment_variables", null)
      secure_environment_variables = lookup(container.value, "secure_environment_variables", null)
      commands                     = lookup(container.value, "commands", null)

      dynamic "ports" {
        for_each = container.value.ports

        content {
          port     = ports.value.port
          protocol = ports.value.protocol
        }
      }
    }
  }

  tags = var.tags
}