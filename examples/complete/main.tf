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
          image    = "busybox:1.36"
          commands = ["sh", "-c", "echo seeded > /scratch/marker"]
          volumes = [
            { name = "scratch", mount_path = "/scratch", empty_dir = true }
          ]
        }
      ]

      containers = [
        {
          name   = "nginx"
          image  = "nginx:1.27-alpine"
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
          image                        = "busybox:1.36"
          cpu                          = 0.25
          memory                       = 0.5
          commands                     = ["sh", "-c", "while true; do sleep 3600; done"]
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
