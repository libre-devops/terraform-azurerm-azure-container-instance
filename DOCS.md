## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_container_group.aci](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_group) | resource |
| [azurerm_network_profile.net_prof](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_profile) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_container_instance_name"></a> [container\_instance\_name](#input\_container\_instance\_name) | The name of the container instance | `string` | n/a | yes |
| <a name="input_dns_name_label"></a> [dns\_name\_label](#input\_dns\_name\_label) | The name of a DNS label if used | `string` | `null` | no |
| <a name="input_identity_ids"></a> [identity\_ids](#input\_identity\_ids) | Specifies a list of user managed identity ids to be assigned to the VM. | `list(string)` | `[]` | no |
| <a name="input_identity_type"></a> [identity\_type](#input\_identity\_type) | The Managed Service Identity Type of this Virtual Machine. | `string` | `""` | no |
| <a name="input_ip_address_type"></a> [ip\_address\_type](#input\_ip\_address\_type) | What the ip address type is if used | `string` | `null` | no |
| <a name="input_key_vault_key_id"></a> [key\_vault\_key\_id](#input\_key\_vault\_key\_id) | If a CMK is used, the key ID used to encrypt the instances | `string` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | The location for this resource to be put in | `string` | n/a | yes |
| <a name="input_network_profile_name"></a> [network\_profile\_name](#input\_network\_profile\_name) | If a private network is used, the name of that network profile. | `string` | `null` | no |
| <a name="input_os_type"></a> [os\_type](#input\_os\_type) | The OS type for the container instance | `string` | n/a | yes |
| <a name="input_restart_policy"></a> [restart\_policy](#input\_restart\_policy) | The restart policy of the container, defaults to Always | `string` | `"Always"` | no |
| <a name="input_rg_name"></a> [rg\_name](#input\_rg\_name) | The name of the resource group, this module does not create a resource group, it is expecting the value of a resource group already exists | `string` | n/a | yes |
| <a name="input_settings"></a> [settings](#input\_settings) | Specifies the Authentication enabled or not | `any` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of the tags to use on the resources that are deployed with this module. | `map(string)` | <pre>{<br>  "source": "terraform"<br>}</pre> | no |
| <a name="input_vnet_integration_enabled"></a> [vnet\_integration\_enabled](#input\_vnet\_integration\_enabled) | If vnet integration is enabled. can only be activated on a Linux container | `bool` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aci_id"></a> [aci\_id](#output\_aci\_id) | The id of the container instance |
| <a name="output_aci_name"></a> [aci\_name](#output\_aci\_name) | The name of the Azure container instance |
| <a name="output_aci_network_profile_interface"></a> [aci\_network\_profile\_interface](#output\_aci\_network\_profile\_interface) | The interface block |
| <a name="output_aci_network_profile_interface_ids"></a> [aci\_network\_profile\_interface\_ids](#output\_aci\_network\_profile\_interface\_ids) | The interface Ids |
| <a name="output_aci_principal_id"></a> [aci\_principal\_id](#output\_aci\_principal\_id) | Client ID of system assigned managed identity if created |
