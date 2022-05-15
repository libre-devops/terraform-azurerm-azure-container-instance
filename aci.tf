resource "azurerm_container_group" "aci" {
  name                = var.container_instance_name
  location            = var.location
  resource_group_name = var.rg_name
  tags                = var.tags
  ip_address_type     = var.vnet_integration_enabled && var.os_type == "Linux" ? var.ip_address_type : null
  network_profile_id  = var.vnet_integration_enabled && var.os_type == "Linux" ? azurerm_network_profile.net_prof.0.id : null
  dns_name_label      = var.vnet_integration_enabled && var.os_type == "Linux" ? null : coalesce(var.dns_name_label, var.container_instance_name)
  os_type             = title(var.os_type)
  restart_policy      = var.restart_policy
  key_vault_key_id    = try(var.key_vault_key_id, null)

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
      nameservers    = tolist(lookup(var.settings.dns_config, "nameservers", null))
      search_domains = tolist(lookup(var.settings.dns_config, "search_domains", null))
      options        = tolist(lookup(var.settings.dns_config, "options", null))
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

  dynamic "exposed_port" {
    for_each = try(var.settings.exposed_port, [])

    content {
      port     = exposed_port.value.port
      protocol = upper(exposed_port.value.protocol)
    }
  }

  # Create containers based on for_each
  dynamic "container" {
    for_each = lookup(var.settings, "container", {}) != {} ? [1] : []

    content {
      name                         = lookup(var.settings.container, "name", null)
      image                        = lookup(var.settings.container, "image", null)
      cpu                          = lookup(var.settings.container, "cpu", null)
      memory                       = lookup(var.settings.container, "memory", null)
      environment_variables        = lookup(var.settings.container, "environment_variables", null)
      secure_environment_variables = lookup(var.settings.container, "secure_environment_variables", null)
      commands                     = lookup(var.settings.container, "commands", null)

      dynamic "gpu" {
        for_each = try(container.value.gpu, null) == null ? [] : [1]

        content {
          count = gpu.value.count
          sku   = gpu.value.sku
        }
      }

      dynamic "ports" {
        for_each = try(container.value.ports, {})

        content {
          port     = can(container.value.iterator) ? tonumber(ports.value.port) + container.value.iterator : ports.value.port
          protocol = try(upper(ports.value.protocol), "TCP")
        }
      }

      dynamic "readiness_probe" {
        for_each = try(container.value.readiness_probe, null) == null ? [] : [1]

        content {
          exec                  = try(readiness_probe.value.exec, null)
          initial_delay_seconds = try(readiness_probe.value.initial_delay_seconds, null)
          period_seconds        = try(readiness_probe.value.period_seconds, 10)
          failure_threshold     = try(readiness_probe.value.failure_threshold, 3)
          success_threshold     = try(readiness_probe.value.success_threshold, 1)
          timeout_seconds       = try(readiness_probe.value.timeout_seconds, 1)

          dynamic "http_get" {
            for_each = try(readiness_probe.value.http_get, {}) == {} ? [] : [1]

            content {
              path   = try(http_get.value.path, null)
              port   = try(http_get.value.port, null)
              scheme = try(http_get.value.scheme, null)
            }
          }
        }
      }

      dynamic "liveness_probe" {
        for_each = try(container.value.liveness_probe, null) == null ? [] : [1]

        content {
          exec                  = try(liveness_probe.value.exec, null)
          initial_delay_seconds = try(liveness_probe.value.initial_delay_seconds, null)
          period_seconds        = try(liveness_probe.value.period_seconds, 10)
          failure_threshold     = try(liveness_probe.value.failure_threshold, 3)
          success_threshold     = try(liveness_probe.value.success_threshold, 1)
          timeout_seconds       = try(liveness_probe.value.timeout_seconds, 1)

          dynamic "http_get" {
            for_each = try(liveness_probe.value.http_get, {}) == {} ? [] : [1]

            content {
              path   = try(http_get.value.path, null)
              port   = try(http_get.value.port, null)
              scheme = try(http_get.value.scheme, null)
            }
          }
        }
      }

      dynamic "volume" {
        for_each = try(container.value.volume, null) == null ? [] : [1]

        content {
          name                 = volume.value.name
          mount_path           = volume.value.mount_path
          read_only            = try(volume.value.read_only, false)
          empty_dir            = try(volume.value.empty_dir, false)
          storage_account_name = try(volume.value.storage_account_name, null)
          storage_account_key  = try(volume.value.storage_account_key, null)
          share_name           = try(volume.value.share_name, null)
          secret               = try(volume.share.secret, null)

          dynamic "git_repo" {
            for_each = try(volume.value.git_repo, null) == null ? [] : [1]

            content {
              url       = git_repo.value.url
              directory = try(git_repo.value.directory, null)
              revision  = try(git_repo.value.revision, null)
            }
          }
        }
      }
    }
  }

  dynamic "init_container" {
    for_each = lookup(var.settings, "init_container", {}) != {} ? [1] : []

    content {
      name = init_container.key

      image                        = init_container.value.image
      environment_variables        = lookup(init_container.value, "environment_variables", null)
      secure_environment_variables = lookup(init_container.value, "secure_environment_variables", null)
      commands                     = lookup(init_container.value, "commands", null)

      dynamic "volume" {
        for_each = try(init_container.value.volume, null) == null ? [] : [1]

        content {
          name                 = volume.value.name
          mount_path           = volume.value.mount_path
          read_only            = try(volume.value.read_only, false)
          empty_dir            = try(volume.value.empty_dir, false)
          storage_account_name = try(volume.value.storage_account_name, null)
          storage_account_key  = try(volume.value.storage_account_key, null)
          share_name           = try(volume.value.share_name, null)
          secret               = try(volume.share.secret, null)
        }
      }
    }
  }
}