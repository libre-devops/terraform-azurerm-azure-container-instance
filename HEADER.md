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
