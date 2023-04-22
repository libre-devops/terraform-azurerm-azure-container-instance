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
        for_each = lookup(var.settings.container, "gpu", {}) != {} ? [1] : []

        content {
          count = lookup(var.settings.container.gpu, "count", null)
          sku   = lookup(var.settings.container.gpu, "sku", null)
        }
      }

      dynamic "ports" {
        for_each = lookup(var.settings.container, "ports", {}) != {} ? [1] : []

        content {
          port     = lookup(var.settings.container.ports, "port", null)
          protocol = upper(lookup(var.settings.container.ports, "protocol", null))
        }
      }

      dynamic "readiness_probe" {
        for_each = lookup(var.settings.container, "readiness_probe", {}) != {} ? [1] : []

        content {
          exec                  = lookup(var.settings.container.readiness_probe, "exec", null)
          initial_delay_seconds = lookup(var.settings.container.readiness_probe, "initial_delay_seconds", null)
          period_seconds        = lookup(var.settings.container.readiness_probe, "period_seconds", null)
          failure_threshold     = lookup(var.settings.container.readiness_probe, "failure_threshold", null)
          success_threshold     = lookup(var.settings.container.readiness_probe, "success_threshold", null)
          timeout_seconds       = lookup(var.settings.container.readiness_probe, "timeout_seconds", null)

          dynamic "http_get" {
            for_each = lookup(var.settings.container.readiness_probe, "http_get", {}) != {} ? [1] : []

            content {
              path   = lookup(var.settings.container.readiness_probe.http_get, "path", null)
              port   = lookup(var.settings.container.readiness_probe.http_get, "port", null)
              scheme = lookup(var.settings.container.readiness_probe.http_get, "scheme", null)
            }
          }
        }
      }

      dynamic "liveness_probe" {
        for_each = lookup(var.settings.container, "liveness_probe", {}) != {} ? [1] : []

        content {
          exec                  = lookup(var.settings.container.liveness_probe, "exec", null)
          initial_delay_seconds = lookup(var.settings.container.liveness_probe, "initial_delay_seconds", null)
          period_seconds        = lookup(var.settings.container.liveness_probe, "period_seconds", null)
          failure_threshold     = lookup(var.settings.container.liveness_probe, "failure_threshold", null)
          success_threshold     = lookup(var.settings.container.liveness_probe, "success_threshold", null)
          timeout_seconds       = lookup(var.settings.container.liveness_probe, "timeout_seconds", null)

          dynamic "http_get" {
            for_each = lookup(var.settings.container.liveness_probe, "http_get", {}) != {} ? [1] : []

            content {
              path   = lookup(var.settings.container.liveness_probe.http_get, "path", null)
              port   = lookup(var.settings.container.liveness_probe.http_get, "port", null)
              scheme = lookup(var.settings.container.liveness_probe.http_get, "scheme", null)
            }
          }
        }
      }

      dynamic "volume" {
        for_each = lookup(var.settings.container, "volume", {}) != {} ? [1] : []

        content {
          name                 = lookup(var.settings.container.volume, "name", null)
          mount_path           = lookup(var.settings.container.volume, "mount_path", null)
          read_only            = lookup(var.settings.container.volume, "read_only", null)
          empty_dir            = lookup(var.settings.container.volume, "empty_dir", null)
          storage_account_name = lookup(var.settings.container.volume, "storage_account_name", null)
          storage_account_key  = lookup(var.settings.container.volume, "storage_account_key", null)
          share_name           = lookup(var.settings.container.volume, "share_name", null)
          secret               = lookup(var.settings.container.volume, "secret", null)

          dynamic "git_repo" {
            for_each = lookup(var.settings.container.volume, "git_repo", {}) != {} ? [1] : []

            content {
              url       = lookup(var.settings.container.volume.git_repo, "url", null)
              directory = lookup(var.settings.container.volume.git_repo, "directory", null)
              revision  = lookup(var.settings.container.volume.git_repo, "revision", null)
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
