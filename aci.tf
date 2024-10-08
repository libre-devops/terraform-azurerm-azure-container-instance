resource "azurerm_container_group" "aci" {
  name                = var.container_instance_name
  location            = var.location
  resource_group_name = var.rg_name
  tags                = var.tags
  ip_address_type     = var.vnet_integration_enabled && var.os_type == "Linux" ? var.ip_address_type : null
  subnet_ids          = try(var.subnet_ids, [], null)
  network_profile_id  = var.vnet_integration_enabled && var.use_legacy_network_profile == true && var.os_type == "Linux" ? azurerm_network_profile.net_prof.0.id : null
  dns_name_label      = var.vnet_integration_enabled && var.os_type == "Linux" ? null : coalesce(var.dns_name_label, var.container_instance_name)
  os_type             = title(var.os_type)
  restart_policy      = title(var.restart_policy)
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

  dynamic "identity" {
    for_each = length(var.identity_ids) > 0 || var.identity_type == "SystemAssigned, UserAssigned" ? [var.identity_type] : []
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
    for_each = lookup(var.settings, "exposed_port", {}) != {} ? [1] : []

    content {
      port     = lookup(var.settings.exposed_port, "port", null)
      protocol = upper(lookup(var.settings.exposed_port, "protocol", null))
    }
  }

  # Create containers based on for_each
  dynamic "container" {
    for_each = lookup(var.settings, "containers", []) != [] ? var.settings.containers : []

    content {
      name                         = container.value.name
      image                        = container.value.image
      cpu                          = container.value.cpu
      memory                       = container.value.memory
      environment_variables        = lookup(container.value, "environment_variables", null)
      secure_environment_variables = lookup(container.value, "secure_environment_variables", null)
      commands                     = lookup(container.value, "commands", null)

      dynamic "gpu" {
        for_each = lookup(container.value, "gpu", []) != [] ? [container.value.gpu] : []

        content {
          count = gpu.value.count
          sku   = gpu.value.sku
        }
      }

      dynamic "ports" {
        for_each = lookup(container.value, "ports", []) != [] ? [container.value.ports] : []

        content {
          port     = ports.value.port
          protocol = upper(ports.value.protocol)
        }
      }

      dynamic "readiness_probe" {
        for_each = lookup(container.value, "readiness_probe", []) != [] ? [container.value.readiness_probe] : []

        content {
          exec                  = lookup(readiness_probe.value, "exec", null)
          initial_delay_seconds = lookup(readiness_probe.value, "initial_delay_seconds", null)
          period_seconds        = lookup(readiness_probe.value, "period_seconds", null)
          failure_threshold     = lookup(readiness_probe.value, "failure_threshold", null)
          success_threshold     = lookup(readiness_probe.value, "success_threshold", null)
          timeout_seconds       = lookup(readiness_probe.value, "timeout_seconds", null)

          dynamic "http_get" {
            for_each = lookup(readiness_probe.value, "http_get", {}) != {} ? [readiness_probe.value.http_get] : []

            content {
              path   = http_get.value.path
              port   = http_get.value.port
              scheme = http_get.value.scheme
            }
          }
        }
      }

      dynamic "liveness_probe" {
        for_each = lookup(container.value, "liveness_probe", {}) != {} ? [container.value.liveness_probe] : []

        content {
          exec                  = lookup(liveness_probe.value, "exec", null)
          initial_delay_seconds = lookup(liveness_probe.value, "initial_delay_seconds", null)
          period_seconds        = lookup(liveness_probe.value, "period_seconds", null)
          failure_threshold     = lookup(liveness_probe.value, "failure_threshold", null)
          success_threshold     = lookup(liveness_probe.value, "success_threshold", null)
          timeout_seconds       = lookup(liveness_probe.value, "timeout_seconds", null)

          dynamic "http_get" {
            for_each = lookup(liveness_probe.value, "http_get", {}) != {} ? [liveness_probe.value.http_get] : []

            content {
              path   = http_get.value.path
              port   = http_get.value.port
              scheme = http_get.value.scheme
            }
          }
        }
      }

      dynamic "volume" {
        for_each = lookup(container.value, "volume", {}) != {} ? [container.value.volume] : []

        content {
          name                 = volume.value.name
          mount_path           = volume.value.mount_path
          read_only            = volume.value.read_only
          empty_dir            = volume.value.empty_dir
          storage_account_name = volume.value.storage_account_name
          storage_account_key  = volume.value.storage_account_key
          share_name           = volume.value.share_name
          secret               = volume.value.secret

          dynamic "git_repo" {
            for_each = lookup(volume.value, "git_repo", {}) != {} ? [volume.value.git_repo] : []

            content {
              url       = git_repo.value.url
              directory = git_repo.value.directory
              revision  = git_repo.value.revision
            }
          }
        }
      }
    }
  }



  dynamic "init_container" {
    for_each = lookup(var.settings, "init_container", {}) != {} ? [1] : []

    content {
      name                         = lookup(var.settings.init_container, "name", null)
      image                        = lookup(var.settings.init_container, "image", null)
      environment_variables        = lookup(var.settings.init_container, "environment_variables", null)
      secure_environment_variables = lookup(var.settings.init_container, "secure_environment_variables", null)
      commands                     = lookup(var.settings.init_container, "commands", null)

      dynamic "volume" {
        for_each = lookup(var.settings.init_container, "volume", {}) != {} ? [1] : []


        content {
          name                 = lookup(var.settings.init_container.volume, "name", null)
          mount_path           = lookup(var.settings.init_container.volume, "mount_path", null)
          read_only            = lookup(var.settings.init_container.volume, "read_only", null)
          empty_dir            = lookup(var.settings.init_container.volume, "empty_dir", null)
          storage_account_name = lookup(var.settings.init_container.volume, "storage_account_name", null)
          storage_account_key  = lookup(var.settings.init_container.volume, "storage_account_key", null)
          share_name           = lookup(var.settings.init_container.volume, "share_name", null)
          secret               = lookup(var.settings.init_container.volume, "secret", null)

          dynamic "git_repo" {
            for_each = lookup(var.settings.init_container.volume, "git_repo", {}) != {} ? [1] : []

            content {
              url       = lookup(var.settings.init_container.volume.git_repo, "url", null)
              directory = lookup(var.settings.init_container.volume.git_repo, "directory", null)
              revision  = lookup(var.settings.init_container.volume.git_repo, "revision", null)
            }
          }
        }
      }
    }
  }
}


resource "azurerm_network_profile" "net_prof" {
  count               = var.vnet_integration_enabled && var.use_legacy_network_profile == true && var.os_type == "Linux" ? 1 : 0
  location            = var.location
  name                = var.network_profile_name
  resource_group_name = var.rg_name
  tags                = var.tags

  dynamic "container_network_interface" {
    for_each = var.vnet_integration_enabled == true && var.os_type == "Linux" && lookup(var.settings, "container_network_interface", {}) != {} ? [1] : []

    content {
      name = lookup(var.settings.container_network_interface, "name", null)

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
