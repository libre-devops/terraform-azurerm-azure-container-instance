variable "container_groups" {
  description = <<-DESC
    Azure container groups (container instances) keyed by name. Fast to get going: an entry with
    an os_type and one container (name, image, cpu, memory) runs, with a public IP and a DNS
    label. Flexible when it matters: multiple containers per group, init containers, probes,
    volumes, private-registry credentials, identity, and VNet placement.

    NETWORKING: ip_address_type defaults to Public with a dns_name_label so the group gets a
    stable FQDN; set ip_address_type = "Private" with subnet_ids for a VNet-integrated group (no
    public IP), or "None" for no inbound. restart_policy defaults to Always.

    SECRETS: use secure_environment_variables (not environment_variables) for anything sensitive,
    and image_registry_credential to pull from a private registry (by username/password or a
    user-assigned identity).
  DESC
  type = map(object({
    os_type                     = optional(string, "Linux")
    ip_address_type             = optional(string, "Public")
    dns_name_label              = optional(string)
    dns_name_label_reuse_policy = optional(string)
    restart_policy              = optional(string, "Always")
    sku                         = optional(string)
    priority                    = optional(string)
    subnet_ids                  = optional(list(string))
    zones                       = optional(list(string))

    key_vault_key_id                    = optional(string)
    key_vault_user_assigned_identity_id = optional(string)

    identity = optional(object({
      type         = string
      identity_ids = optional(list(string))
    }))

    image_registry_credentials = optional(list(object({
      server                    = string
      username                  = optional(string)
      password                  = optional(string)
      user_assigned_identity_id = optional(string)
    })), [])

    dns_config = optional(object({
      nameservers    = list(string)
      search_domains = optional(list(string))
      options        = optional(list(string))
    }))

    diagnostics_log_analytics = optional(object({
      workspace_id  = string
      workspace_key = string
      log_type      = optional(string)
      metadata      = optional(map(string))
    }))

    containers = list(object({
      name                         = string
      image                        = string
      cpu                          = number
      memory                       = number
      cpu_limit                    = optional(number)
      memory_limit                 = optional(number)
      commands                     = optional(list(string))
      environment_variables        = optional(map(string))
      secure_environment_variables = optional(map(string))

      ports = optional(list(object({
        port     = number
        protocol = optional(string, "TCP")
      })), [])

      liveness_probe = optional(object({
        exec                  = optional(list(string))
        initial_delay_seconds = optional(number)
        period_seconds        = optional(number)
        failure_threshold     = optional(number)
        success_threshold     = optional(number)
        timeout_seconds       = optional(number)
        http_get = optional(object({
          path         = optional(string)
          port         = optional(number)
          scheme       = optional(string)
          http_headers = optional(map(string))
        }))
      }))

      readiness_probe = optional(object({
        exec                  = optional(list(string))
        initial_delay_seconds = optional(number)
        period_seconds        = optional(number)
        failure_threshold     = optional(number)
        success_threshold     = optional(number)
        timeout_seconds       = optional(number)
        http_get = optional(object({
          path         = optional(string)
          port         = optional(number)
          scheme       = optional(string)
          http_headers = optional(map(string))
        }))
      }))

      security = optional(object({
        privilege_enabled = bool
      }))

      volumes = optional(list(object({
        name                 = string
        mount_path           = string
        read_only            = optional(bool)
        empty_dir            = optional(bool)
        share_name           = optional(string)
        storage_account_name = optional(string)
        storage_account_key  = optional(string)
        secret               = optional(map(string))
        git_repo = optional(object({
          url       = string
          directory = optional(string)
          revision  = optional(string)
        }))
      })), [])
    }))

    init_containers = optional(list(object({
      name                         = string
      image                        = string
      commands                     = optional(list(string))
      environment_variables        = optional(map(string))
      secure_environment_variables = optional(map(string))
      security = optional(object({
        privilege_enabled = bool
      }))
      volumes = optional(list(object({
        name                 = string
        mount_path           = string
        read_only            = optional(bool)
        empty_dir            = optional(bool)
        share_name           = optional(string)
        storage_account_name = optional(string)
        storage_account_key  = optional(string)
        secret               = optional(map(string))
        git_repo = optional(object({
          url       = string
          directory = optional(string)
          revision  = optional(string)
        }))
      })), [])
    })), [])

    tags = optional(map(string))
  }))
  default = {}

  validation {
    condition     = alltrue([for g in values(var.container_groups) : contains(["Linux", "Windows"], g.os_type)])
    error_message = "os_type must be Linux or Windows."
  }

  validation {
    condition     = alltrue([for g in values(var.container_groups) : contains(["Public", "Private", "None"], g.ip_address_type)])
    error_message = "ip_address_type must be Public, Private, or None."
  }

  validation {
    condition     = alltrue([for g in values(var.container_groups) : g.ip_address_type != "Private" || (g.subnet_ids != null && length(coalesce(g.subnet_ids, [])) > 0)])
    error_message = "A Private container group requires subnet_ids."
  }

  validation {
    condition     = alltrue([for g in values(var.container_groups) : length(g.containers) > 0])
    error_message = "Each container group needs at least one container."
  }
}

variable "location" {
  description = "Azure region for all container groups in this module."
  type        = string
}

variable "resource_group_id" {
  description = "Id of the resource group the container groups live in; the module parses the name from it."
  type        = string
}

variable "tags" {
  description = "Tags applied to all container groups; per-group tags override these."
  type        = map(string)
  default     = {}
}
