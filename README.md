<!--
  Keep the title and badges OUTSIDE the centered <div>: the Terraform Registry's markdown renderer
  does not parse markdown inside an HTML block, so a # heading or [![badge]] in the div renders as
  literal text on the registry. Only the logo (HTML) goes in the div.
-->
<div align="center">
  <a href="https://libredevops.org">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://libredevops.org/assets/libre-devops-white.png">
      <img alt="Libre DevOps" src="https://libredevops.org/assets/libre-devops-black.png" width="300">
    </picture>
  </a>
</div>

# Terraform Azure Container Instance

Terraform module for Azure Container Instances (container groups), in the Libre DevOps style:
fast to get going, secure by default, flexible when it matters.

[![CI](https://github.com/libre-devops/terraform-azurerm-azure-container-instance/actions/workflows/ci.yml/badge.svg)](https://github.com/libre-devops/terraform-azurerm-azure-container-instance/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/libre-devops/terraform-azurerm-azure-container-instance?sort=semver&label=release)](https://github.com/libre-devops/terraform-azurerm-azure-container-instance/releases/latest)
[![Terraform Registry](https://img.shields.io/badge/registry-libre--devops-7B42BC?logo=terraform&logoColor=white)](https://registry.terraform.io/namespaces/libre-devops)
[![License](https://img.shields.io/github/license/libre-devops/terraform-azurerm-azure-container-instance)](./LICENSE)

---

## Overview

```hcl
module "container_instance" {
  source  = "libre-devops/azure-container-instance/azurerm"
  version = "~> 4.0"

  resource_group_id = module.rg.ids["rg-ldo-uks-dev-001"]
  location          = "uksouth"
  tags              = module.tags.tags

  container_groups = {
    "aci-ldo-uks-dev-001" = {
      dns_name_label = "aci-ldo-uks-dev-001"
      containers = [{
        name   = "nginx"
        image  = "nginx:1.27-alpine"
        cpu    = 0.5
        memory = 1.0
        ports  = [{ port = 80 }]
      }]
    }
  }
}
```

That entry runs an nginx container on a public IP with a stable FQDN. Every knob is an explicit
override.

- **Groups as a map, containers as a list.** Provision many groups in one call, each with one or
  more containers plus optional init containers that run to completion first.
- **Secure by convention.** Put sensitive values in `secure_environment_variables` (never
  `environment_variables`), and pull from a private registry with `image_registry_credential`
  (username/password or a user-assigned identity). Public IP with a DNS label is the default;
  set `ip_address_type = "Private"` with `subnet_ids` for a VNet-integrated group (a validation
  enforces the subnet), or `"None"` for no inbound.
- **The full container surface.** cpu/memory requests and limits, ports, liveness and readiness
  probes (exec or http_get), volumes (Azure Files, empty_dir, git_repo, or secret), commands,
  and per-container `security` (privileged) are all exposed, on both containers and init
  containers.
- **Group extras.** Identity, a Log Analytics diagnostics sink, custom `dns_config`, zones,
  priority, and confidential/dedicated `sku` are there when you want them.

## Examples

- [`examples/minimal`](./examples/minimal) - one public nginx group, applied, curled, and
  destroyed in CI.
- [`examples/complete`](./examples/complete) - a group with an init container writing a scratch
  volume, an nginx container with a liveness probe, a busybox sidecar with a secure environment
  variable, and a system-assigned identity.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0, < 2.0.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.0.0, < 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.80.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_container_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_container_groups"></a> [container\_groups](#input\_container\_groups) | Azure container groups (container instances) keyed by name. Fast to get going: an entry with<br/>an os\_type and one container (name, image, cpu, memory) runs, with a public IP and a DNS<br/>label. Flexible when it matters: multiple containers per group, init containers, probes,<br/>volumes, private-registry credentials, identity, and VNet placement.<br/><br/>NETWORKING: ip\_address\_type defaults to Public with a dns\_name\_label so the group gets a<br/>stable FQDN; set ip\_address\_type = "Private" with subnet\_ids for a VNet-integrated group (no<br/>public IP), or "None" for no inbound. restart\_policy defaults to Always.<br/><br/>SECRETS: use secure\_environment\_variables (not environment\_variables) for anything sensitive,<br/>and image\_registry\_credential to pull from a private registry (by username/password or a<br/>user-assigned identity). | <pre>map(object({<br/>    os_type                     = optional(string, "Linux")<br/>    ip_address_type             = optional(string, "Public")<br/>    dns_name_label              = optional(string)<br/>    dns_name_label_reuse_policy = optional(string)<br/>    restart_policy              = optional(string, "Always")<br/>    sku                         = optional(string)<br/>    priority                    = optional(string)<br/>    subnet_ids                  = optional(list(string))<br/>    zones                       = optional(list(string))<br/><br/>    key_vault_key_id                    = optional(string)<br/>    key_vault_user_assigned_identity_id = optional(string)<br/><br/>    identity = optional(object({<br/>      type         = string<br/>      identity_ids = optional(list(string))<br/>    }))<br/><br/>    image_registry_credentials = optional(list(object({<br/>      server                    = string<br/>      username                  = optional(string)<br/>      password                  = optional(string)<br/>      user_assigned_identity_id = optional(string)<br/>    })), [])<br/><br/>    dns_config = optional(object({<br/>      nameservers    = list(string)<br/>      search_domains = optional(list(string))<br/>      options        = optional(list(string))<br/>    }))<br/><br/>    diagnostics_log_analytics = optional(object({<br/>      workspace_id  = string<br/>      workspace_key = string<br/>      log_type      = optional(string)<br/>      metadata      = optional(map(string))<br/>    }))<br/><br/>    containers = list(object({<br/>      name                         = string<br/>      image                        = string<br/>      cpu                          = number<br/>      memory                       = number<br/>      cpu_limit                    = optional(number)<br/>      memory_limit                 = optional(number)<br/>      commands                     = optional(list(string))<br/>      environment_variables        = optional(map(string))<br/>      secure_environment_variables = optional(map(string))<br/><br/>      ports = optional(list(object({<br/>        port     = number<br/>        protocol = optional(string, "TCP")<br/>      })), [])<br/><br/>      liveness_probe = optional(object({<br/>        exec                  = optional(list(string))<br/>        initial_delay_seconds = optional(number)<br/>        period_seconds        = optional(number)<br/>        failure_threshold     = optional(number)<br/>        success_threshold     = optional(number)<br/>        timeout_seconds       = optional(number)<br/>        http_get = optional(object({<br/>          path         = optional(string)<br/>          port         = optional(number)<br/>          scheme       = optional(string)<br/>          http_headers = optional(map(string))<br/>        }))<br/>      }))<br/><br/>      readiness_probe = optional(object({<br/>        exec                  = optional(list(string))<br/>        initial_delay_seconds = optional(number)<br/>        period_seconds        = optional(number)<br/>        failure_threshold     = optional(number)<br/>        success_threshold     = optional(number)<br/>        timeout_seconds       = optional(number)<br/>        http_get = optional(object({<br/>          path         = optional(string)<br/>          port         = optional(number)<br/>          scheme       = optional(string)<br/>          http_headers = optional(map(string))<br/>        }))<br/>      }))<br/><br/>      security = optional(object({<br/>        privilege_enabled = bool<br/>      }))<br/><br/>      volumes = optional(list(object({<br/>        name                 = string<br/>        mount_path           = string<br/>        read_only            = optional(bool)<br/>        empty_dir            = optional(bool)<br/>        share_name           = optional(string)<br/>        storage_account_name = optional(string)<br/>        storage_account_key  = optional(string)<br/>        secret               = optional(map(string))<br/>        git_repo = optional(object({<br/>          url       = string<br/>          directory = optional(string)<br/>          revision  = optional(string)<br/>        }))<br/>      })), [])<br/>    }))<br/><br/>    init_containers = optional(list(object({<br/>      name                         = string<br/>      image                        = string<br/>      commands                     = optional(list(string))<br/>      environment_variables        = optional(map(string))<br/>      secure_environment_variables = optional(map(string))<br/>      security = optional(object({<br/>        privilege_enabled = bool<br/>      }))<br/>      volumes = optional(list(object({<br/>        name                 = string<br/>        mount_path           = string<br/>        read_only            = optional(bool)<br/>        empty_dir            = optional(bool)<br/>        share_name           = optional(string)<br/>        storage_account_name = optional(string)<br/>        storage_account_key  = optional(string)<br/>        secret               = optional(map(string))<br/>        git_repo = optional(object({<br/>          url       = string<br/>          directory = optional(string)<br/>          revision  = optional(string)<br/>        }))<br/>      })), [])<br/>    })), [])<br/><br/>    tags = optional(map(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region for all container groups in this module. | `string` | n/a | yes |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | Id of the resource group the container groups live in; the module parses the name from it. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to all container groups; per-group tags override these. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_container_group_ids"></a> [container\_group\_ids](#output\_container\_group\_ids) | Map of group name to id. |
| <a name="output_container_group_ids_zipmap"></a> [container\_group\_ids\_zipmap](#output\_container\_group\_ids\_zipmap) | Map of group name to { name, id } for easy composition. |
| <a name="output_container_groups"></a> [container\_groups](#output\_container\_groups) | Map of group name to the full container group object. Sensitive as a whole because it carries secure environment variables and volume secrets; the ids, IPs, and FQDNs alongside stay plain for composition. |
| <a name="output_fqdns"></a> [fqdns](#output\_fqdns) | Map of group name to its fully qualified domain name (public groups with a dns\_name\_label). |
| <a name="output_identity_principal_ids"></a> [identity\_principal\_ids](#output\_identity\_principal\_ids) | Map of group name to { system\_assigned } principal id (null where absent). |
| <a name="output_ip_addresses"></a> [ip\_addresses](#output\_ip\_addresses) | Map of group name to its IP address. |
<!-- END_TF_DOCS -->
