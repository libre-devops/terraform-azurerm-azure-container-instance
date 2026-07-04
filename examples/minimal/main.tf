# Minimal call: one public Linux container group running nginx, reachable on its FQDN. Applied,
# curled, then destroyed in one CI run.
locals {
  location  = lookup(var.regions, var.loc, "uksouth")
  rg_name   = "rg-${var.short}-${var.loc}-${terraform.workspace}-001"
  aci_name  = "aci-${var.short}-${var.loc}-${terraform.workspace}-001"
  dns_label = "aci-${var.short}-${var.loc}-${terraform.workspace}-001"
}

module "tags" {
  source  = "libre-devops/tags/azurerm"
  version = "~> 4.0"

  cost_centre     = "1888/67"
  owner           = "platform@example.com"
  deployed_branch = var.deployed_branch
  deployed_repo   = var.deployed_repo
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

      containers = [
        {
          name   = "nginx"
          image  = "nginx:1.27-alpine"
          cpu    = 0.5
          memory = 1.0
          ports  = [{ port = 80, protocol = "TCP" }]
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
