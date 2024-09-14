resource "random_string" "random" {
  length  = 6
  special = false
}

locals {
  vnet_address_space  = "10.0.0.0/16"
  now                 = timestamp()
  seven_days_from_now = timeadd(timestamp(), "168h")
}

module "rg" {
  source = "libre-devops/rg/azurerm"

  rg_name  = "rg-${var.short}-${var.loc}-${var.env}-${random_string.random.result}"
  location = local.location
  tags     = local.tags
}

module "subnet_calculator" {
  source = "github.com/libre-devops/terraform-null-subnet-calculator"

  base_cidr    = local.vnet_address_space
  subnet_sizes = [24]
}

module "network" {
  source = "registry.terraform.io/libre-devops/network/azurerm"

  rg_name  = module.rg.rg_name
  location = module.rg.rg_location
  tags     = module.rg.rg_tags

  vnet_name          = "vnet-${var.short}-${var.loc}-${var.env}-${random_string.random.result}"
  vnet_location      = module.rg.rg_location
  vnet_address_space = module.subnet_calculator.base_cidr_set

  subnets = {
    for i, name in module.subnet_calculator.subnet_names :
    name => {
      address_prefixes  = toset([module.subnet_calculator.subnet_ranges[i]])
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
      delegation = [
        {
          type = "Microsoft.ContainerInstance/containerGroups"
        }
      ]
    }
  }
}


module "container_registry" {
  source = "../../"

  depends_on = [
    random_string.random
  ]

  registries = [
    {
      name                  = "acr${var.short}${var.loc}${var.env}01"
      rg_name               = module.rg.rg_name
      location              = module.rg.rg_location
      tags                  = module.rg.rg_tags
      admin_enabled         = true
      sku                   = "Basic"
      export_policy_enabled = true
      identity_type         = "UserAssigned"
      identity_ids          = [azurerm_user_assigned_identity.uid.id]
    },
  ]
}
