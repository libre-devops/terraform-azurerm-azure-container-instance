<!--
  Header for the complete example README. Edit this file, then run `just docs`
  (or ./Sort-LdoTerraform.ps1 -IncludeExamples) to regenerate the section between the markers.
  The example's main.tf is embedded into the README automatically (see .terraform-docs.yml).
-->
<div align="center">
  <a href="https://libredevops.org">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://libredevops.org/assets/libre-devops-white.png">
      <img alt="Libre DevOps" src="https://libredevops.org/assets/libre-devops-black.png" width="200">
    </picture>
  </a>
</div>

# Complete example

A group with an init container writing a scratch volume, a serving container with a liveness probe, a sidecar with a secure environment variable, and a system-assigned identity.

[![Terraform Registry](https://img.shields.io/badge/registry-libre--devops-7B42BC?logo=terraform&logoColor=white)](https://registry.terraform.io/namespaces/libre-devops)

<!-- BEGIN_TF_DOCS -->
## Example configuration

```hcl
# The module's surface: a public Linux group with an init container writing to a scratch volume,
# an nginx container serving its default page with a liveness probe, a busybox sidecar with a
# secure environment variable, and a system-assigned identity. Applied, curled, then destroyed in
# one CI run. (The nginx docroot is deliberately not overmounted so the curl gate is reliable.)
locals {
  location  = lookup(var.regions, var.loc, "uksouth")
  rg_name   = "rg-${var.short}-${var.loc}-${terraform.workspace}-002"
  aci_name  = "aci-${var.short}-${var.loc}-${terraform.workspace}-002"
  dns_label = "aci-${var.short}-${var.loc}-${terraform.workspace}-002"
}

module "tags" {
  source  = "libre-devops/tags/azurerm"
  version = "~> 4.0"

  cost_centre     = "1888/67"
  owner           = "platform@example.com"
  deployed_branch = var.deployed_branch
  deployed_repo   = var.deployed_repo
  additional_tags = { Application = "terraform-azurerm-azure-container-instance" }
}

module "rg" {
  source  = "libre-devops/rg/azurerm"
  version = "~> 4.0"

  resource_groups = [{ name = local.rg_name, location = local.location, tags = module.tags.tags }]
}

module "container_instance" {
  source = "../../"

  resource_group_id = module.rg.ids[local.rg_name]
  location          = local.location
  tags              = module.tags.tags

  container_groups = {
    (local.aci_name) = {
      dns_name_label = local.dns_label

      identity = { type = "SystemAssigned" }

      init_containers = [
        {
          name     = "seed"
          image    = "mcr.microsoft.com/azuredocs/aci-helloworld:latest"
          commands = ["node", "-e", "require('fs').writeFileSync('/scratch/marker','seeded')"]
          volumes = [
            { name = "scratch", mount_path = "/scratch", empty_dir = true }
          ]
        }
      ]

      containers = [
        {
          name   = "nginx"
          image  = "mcr.microsoft.com/azuredocs/aci-helloworld:latest"
          cpu    = 0.5
          memory = 1.0
          ports  = [{ port = 80, protocol = "TCP" }]

          liveness_probe = {
            http_get              = { path = "/", port = 80, scheme = "http" }
            initial_delay_seconds = 5
            period_seconds        = 15
          }
        },
        {
          name                         = "sidecar"
          image                        = "mcr.microsoft.com/azuredocs/aci-helloworld:latest"
          cpu                          = 0.25
          memory                       = 0.5
          commands                     = ["node", "-e", "setInterval(function () {}, 1000000000)"]
          secure_environment_variables = { WORKER_TOKEN = "example-not-a-real-secret" }
        }
      ]
    }
  }
}

output "fqdn" {
  value = module.container_instance.fqdns[local.aci_name]
}

output "resource_group_name" {
  value = local.rg_name
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0, < 2.0.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.0.0, < 5.0.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_container_instance"></a> [container\_instance](#module\_container\_instance) | ../../ | n/a |
| <a name="module_rg"></a> [rg](#module\_rg) | libre-devops/rg/azurerm | ~> 4.0 |
| <a name="module_tags"></a> [tags](#module\_tags) | libre-devops/tags/azurerm | ~> 4.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_deployed_branch"></a> [deployed\_branch](#input\_deployed\_branch) | Git branch the deployment came from. Auto-filled in CI from TF\_VAR\_deployed\_branch. | `string` | `""` | no |
| <a name="input_deployed_repo"></a> [deployed\_repo](#input\_deployed\_repo) | Repository URL the deployment came from. Auto-filled in CI from TF\_VAR\_deployed\_repo. | `string` | `""` | no |
| <a name="input_loc"></a> [loc](#input\_loc) | Outfix: short Azure region code used in resource names (for example uks). | `string` | `"uks"` | no |
| <a name="input_regions"></a> [regions](#input\_regions) | Map of short region codes to Azure region slugs. | `map(string)` | <pre>{<br/>  "eus": "eastus",<br/>  "euw": "westeurope",<br/>  "uks": "uksouth",<br/>  "ukw": "ukwest"<br/>}</pre> | no |
| <a name="input_short"></a> [short](#input\_short) | Infix: short product code used in resource names. | `string` | `"ldo"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_fqdn"></a> [fqdn](#output\_fqdn) | n/a |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | n/a |
<!-- END_TF_DOCS -->
