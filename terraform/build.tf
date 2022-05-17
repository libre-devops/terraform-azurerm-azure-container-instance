module "rg" {
  source = "registry.terraform.io/libre-devops/rg/azurerm"

  rg_name  = "rg-${var.short}-${var.loc}-${terraform.workspace}-build" // rg-ldo-euw-dev-build
  location = local.location                                            // compares var.loc with the var.regions var to match a long-hand name, in this case, "euw", so "westeurope"
  tags     = local.tags

  #  lock_level = "CanNotDelete" // Do not set this value to skip lock
}

module "aci" {
  source = "registry.terraform.io/libre-devops/azure-container-instance/azurerm"

  rg_name  = module.rg.rg_name
  location = module.rg.rg_location
  tags     = module.rg.rg_tags

  container_instance_name  = "aci${var.short}${var.loc}${terraform.workspace}01"
  os_type                  = "Linux"
  vnet_integration_enabled = false
  identity_type            = "SystemAssigned"

  settings = {
    container = {
      name   = "ubuntu-test"
      image  = "docker.io/ubuntu:latest"
      cpu    = "2"
      memory = "2"

      // Ports cannot be empty in Azure.  For security, 443 with no HTTPS listener is probably the best security.
      ports = {
        port     = "443"
        protocol = "TCP"
      }
    }
  }
}