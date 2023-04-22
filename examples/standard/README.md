
```hcl
module "rg" {
  source = "registry.terraform.io/libre-devops/rg/azurerm"

  rg_name  = "rg-${var.short}-${var.loc}-${terraform.workspace}-build" // rg-ldo-euw-dev-build
  location = local.location                                            // compares var.loc with the var.regions var to match a long-hand name, in this case, "euw", so "westeurope"
  tags     = local.tags

  #  lock_level = "CanNotDelete" // Do not set this value to skip lock
}

module "network" {
  source = "registry.terraform.io/libre-devops/network/azurerm"

  rg_name  = module.rg.rg_name
  location = module.rg.rg_location
  tags     = module.rg.rg_tags

  vnet_name     = "vnet-${var.short}-${var.loc}-${terraform.workspace}-01" // vnet-ldo-euw-dev-01
  vnet_location = module.network.vnet_location

  address_space = ["10.0.0.0/16"]
  subnet_prefixes = [
    "10.0.0.0/24",
  ]
  subnet_names = [
    "sn1-${module.network.vnet_name}",
  ]
  subnet_service_endpoints = {
    "sn1-${module.network.vnet_name}" = ["Microsoft.Storage", "Microsoft.Keyvault", "Microsoft.Sql", "Microsoft.Web", "Microsoft.AzureActiveDirectory"], # DevOps
  }

  subnet_delegation = {

    "sn1-${module.network.vnet_name}" = {
      "Microsoft.Web/serverFarms" = {
        service_name    = "Microsoft.ContainerInstance/containerGroups"
        service_actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
  }
}

# Create a NSG with an explict deny at 4096, since this environment needs 5 NSGs, count is set to 5
module "nsg" {
  source   = "registry.terraform.io/libre-devops/nsg/azurerm"
  count    = 1
  rg_name  = module.rg.rg_name
  location = module.rg.rg_location
  tags     = module.rg.rg_tags

  nsg_name  = "nsg-${var.short}-${var.loc}-${terraform.workspace}-${format("%02d", count.index + 1)}" // nsg-ldo-euw-dev-01 - the format("%02d") applies number padding e.g 1 = 01, 2 = 02
  subnet_id = element(values(module.network.subnets_ids), count.index)
}

resource "azurerm_network_security_rule" "vnet_inbound" {
  count = 1 # can't use length() of subnet ids as not known till apply

  name                        = "AllowVnetInbound"
  priority                    = "149"
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = module.rg.rg_name
  network_security_group_name = module.nsg[count.index].nsg_name
}

resource "azurerm_network_security_rule" "bastion_inbound" {
  count = 1 # can't use length() of subnet ids as not known till apply

  name                        = "AllowSSHRDPInbound"
  priority                    = "150"
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["22", "3389"]
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = module.rg.rg_name
  network_security_group_name = module.nsg[count.index].nsg_name
}


module "aci" {
  source = "../.."

  rg_name  = module.rg.rg_name
  location = module.rg.rg_location
  tags     = module.rg.rg_tags

  container_instance_name  = "aci${var.short}${var.loc}${terraform.workspace}01"
  os_type                  = "Linux"
  vnet_integration_enabled = true
  identity_type            = "SystemAssigned"
  ip_address_type          = "Private"
  subnet_ids               = values(module.network.subnets_ids)


  settings = {
    container = {
      name   = "alpine"
      image  = "mcr.microsoft.com/oss/nginx/nginx:1.9.15-alpine"
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
```
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aci"></a> [aci](#module\_aci) | ../.. | n/a |
| <a name="module_network"></a> [network](#module\_network) | registry.terraform.io/libre-devops/network/azurerm | n/a |
| <a name="module_nsg"></a> [nsg](#module\_nsg) | registry.terraform.io/libre-devops/nsg/azurerm | n/a |
| <a name="module_rg"></a> [rg](#module\_rg) | registry.terraform.io/libre-devops/rg/azurerm | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_network_security_rule.bastion_inbound](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.vnet_inbound](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_client_config.current_creds](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_key_vault.mgmt_kv](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault) | data source |
| [azurerm_key_vault_secret.mgmt_local_admin_pwd](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_secret) | data source |
| [azurerm_resource_group.mgmt_rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_ssh_public_key.mgmt_ssh_key](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/ssh_public_key) | data source |
| [azurerm_user_assigned_identity.mgmt_user_assigned_id](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/user_assigned_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_Regions"></a> [Regions](#input\_Regions) | Converts shorthand name to longhand name via lookup on map list | `map(string)` | <pre>{<br>  "eus": "East US",<br>  "euw": "West Europe",<br>  "uks": "UK South",<br>  "ukw": "UK West"<br>}</pre> | no |
| <a name="input_env"></a> [env](#input\_env) | This is passed as an environment variable, it is for the shorthand environment tag for resource.  For example, production = prod | `string` | `"dev"` | no |
| <a name="input_loc"></a> [loc](#input\_loc) | The shorthand name of the Azure location, for example, for UK South, use uks.  For UK West, use ukw. Normally passed as TF\_VAR in pipeline | `string` | `"euw"` | no |
| <a name="input_short"></a> [short](#input\_short) | This is passed as an environment variable, it is for a shorthand name for the environment, for example hello-world = hw | `string` | `"ldo"` | no |

## Outputs

No outputs.
