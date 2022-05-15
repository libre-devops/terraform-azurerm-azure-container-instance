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

  key_vault_key_id = var.key_vault_key_id


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
      name                         = container.value.name
      image                        = container.value.image
      cpu                          = container.value.cpu
      memory                       = container.value.memory
      environment_variables        = merge(try(container.value.environment_variables, null))
      secure_environment_variables = try(container.value.secure_environment_variables, null)
      commands                     = try(container.value.commands, null)

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
          } //http_get
        }
      } //liveness_probe

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