locals {
  rg = provider::azurerm::parse_resource_id(var.resource_group_id)
}

resource "azurerm_container_group" "this" {
  for_each = var.container_groups

  resource_group_name = local.rg.resource_group_name
  location            = var.location
  tags                = merge(var.tags, coalesce(each.value.tags, {}))

  name                                = each.key
  os_type                             = each.value.os_type
  ip_address_type                     = each.value.ip_address_type
  dns_name_label                      = each.value.dns_name_label
  dns_name_label_reuse_policy         = each.value.dns_name_label_reuse_policy
  restart_policy                      = each.value.restart_policy
  sku                                 = each.value.sku
  priority                            = each.value.priority
  subnet_ids                          = each.value.subnet_ids
  zones                               = each.value.zones
  key_vault_key_id                    = each.value.key_vault_key_id
  key_vault_user_assigned_identity_id = each.value.key_vault_user_assigned_identity_id

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []

    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  dynamic "image_registry_credential" {
    for_each = each.value.image_registry_credentials

    content {
      server                    = image_registry_credential.value.server
      username                  = image_registry_credential.value.username
      password                  = image_registry_credential.value.password
      user_assigned_identity_id = image_registry_credential.value.user_assigned_identity_id
    }
  }

  dynamic "dns_config" {
    for_each = each.value.dns_config != null ? [each.value.dns_config] : []

    content {
      nameservers    = dns_config.value.nameservers
      search_domains = dns_config.value.search_domains
      options        = dns_config.value.options
    }
  }

  dynamic "diagnostics" {
    for_each = each.value.diagnostics_log_analytics != null ? [each.value.diagnostics_log_analytics] : []

    content {
      log_analytics {
        workspace_id  = diagnostics.value.workspace_id
        workspace_key = diagnostics.value.workspace_key
        log_type      = diagnostics.value.log_type
        metadata      = diagnostics.value.metadata
      }
    }
  }

  dynamic "container" {
    for_each = { for c in each.value.containers : c.name => c }

    content {
      name                         = container.value.name
      image                        = container.value.image
      cpu                          = container.value.cpu
      memory                       = container.value.memory
      cpu_limit                    = container.value.cpu_limit
      memory_limit                 = container.value.memory_limit
      commands                     = container.value.commands
      environment_variables        = container.value.environment_variables
      secure_environment_variables = container.value.secure_environment_variables

      dynamic "ports" {
        for_each = container.value.ports

        content {
          port     = ports.value.port
          protocol = ports.value.protocol
        }
      }

      dynamic "liveness_probe" {
        for_each = container.value.liveness_probe != null ? [container.value.liveness_probe] : []

        content {
          exec                  = liveness_probe.value.exec
          initial_delay_seconds = liveness_probe.value.initial_delay_seconds
          period_seconds        = liveness_probe.value.period_seconds
          failure_threshold     = liveness_probe.value.failure_threshold
          success_threshold     = liveness_probe.value.success_threshold
          timeout_seconds       = liveness_probe.value.timeout_seconds

          dynamic "http_get" {
            for_each = liveness_probe.value.http_get != null ? [liveness_probe.value.http_get] : []

            content {
              path         = http_get.value.path
              port         = http_get.value.port
              scheme       = http_get.value.scheme
              http_headers = http_get.value.http_headers
            }
          }
        }
      }

      dynamic "readiness_probe" {
        for_each = container.value.readiness_probe != null ? [container.value.readiness_probe] : []

        content {
          exec                  = readiness_probe.value.exec
          initial_delay_seconds = readiness_probe.value.initial_delay_seconds
          period_seconds        = readiness_probe.value.period_seconds
          failure_threshold     = readiness_probe.value.failure_threshold
          success_threshold     = readiness_probe.value.success_threshold
          timeout_seconds       = readiness_probe.value.timeout_seconds

          dynamic "http_get" {
            for_each = readiness_probe.value.http_get != null ? [readiness_probe.value.http_get] : []

            content {
              path         = http_get.value.path
              port         = http_get.value.port
              scheme       = http_get.value.scheme
              http_headers = http_get.value.http_headers
            }
          }
        }
      }

      dynamic "security" {
        for_each = container.value.security != null ? [container.value.security] : []

        content {
          privilege_enabled = security.value.privilege_enabled
        }
      }

      dynamic "volume" {
        for_each = { for v in container.value.volumes : v.name => v }

        content {
          name                 = volume.value.name
          mount_path           = volume.value.mount_path
          read_only            = volume.value.read_only
          empty_dir            = volume.value.empty_dir
          share_name           = volume.value.share_name
          storage_account_name = volume.value.storage_account_name
          storage_account_key  = volume.value.storage_account_key
          secret               = volume.value.secret

          dynamic "git_repo" {
            for_each = volume.value.git_repo != null ? [volume.value.git_repo] : []

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
    for_each = { for c in each.value.init_containers : c.name => c }

    content {
      name                         = init_container.value.name
      image                        = init_container.value.image
      commands                     = init_container.value.commands
      environment_variables        = init_container.value.environment_variables
      secure_environment_variables = init_container.value.secure_environment_variables

      dynamic "security" {
        for_each = init_container.value.security != null ? [init_container.value.security] : []

        content {
          privilege_enabled = security.value.privilege_enabled
        }
      }

      dynamic "volume" {
        for_each = { for v in init_container.value.volumes : v.name => v }

        content {
          name                 = volume.value.name
          mount_path           = volume.value.mount_path
          read_only            = volume.value.read_only
          empty_dir            = volume.value.empty_dir
          share_name           = volume.value.share_name
          storage_account_name = volume.value.storage_account_name
          storage_account_key  = volume.value.storage_account_key
          secret               = volume.value.secret

          dynamic "git_repo" {
            for_each = volume.value.git_repo != null ? [volume.value.git_repo] : []

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
}
