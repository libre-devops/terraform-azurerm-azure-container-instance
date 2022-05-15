output "aci_id" {
  value       = azurerm_container_group.aci.id
  description = "The id of the container instance"
}

output "aci_name" {
  value       = azurerm_container_group.aci.name
  description = "The name of the Azure container instance"
}

output "aci_network_profile_interface" {
  value       = azurerm_network_profile.net_prof[0].container_network_interface
  description = "The interface block"
}

output "aci_network_profile_interface_ids" {
  value       = azurerm_network_profile.net_prof[0].container_network_interface_ids
  description = "The interface Ids"
}

output "aci_principal_id" {
  value       = azurerm_container_group.aci.identity[0].principal_id
  description = "Client ID of system assigned managed identity if created"
}
