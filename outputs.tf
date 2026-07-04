output "container_group_ids" {
  description = "Map of group name to id."
  value       = { for k, g in azurerm_container_group.this : k => g.id }
}

output "container_group_ids_zipmap" {
  description = "Map of group name to { name, id } for easy composition."
  value       = { for k, g in azurerm_container_group.this : k => { name = g.name, id = g.id } }
}

output "container_groups" {
  description = "Map of group name to the full container group object. Sensitive as a whole because it carries secure environment variables and volume secrets; the ids, IPs, and FQDNs alongside stay plain for composition."
  value       = azurerm_container_group.this
  sensitive   = true
}

output "fqdns" {
  description = "Map of group name to its fully qualified domain name (public groups with a dns_name_label)."
  value       = { for k, g in azurerm_container_group.this : k => g.fqdn }
}

output "identity_principal_ids" {
  description = "Map of group name to { system_assigned } principal id (null where absent)."
  value = {
    for k, g in azurerm_container_group.this : k => {
      system_assigned = try(g.identity[0].principal_id, null)
    }
  }
}

output "ip_addresses" {
  description = "Map of group name to its IP address."
  value       = { for k, g in azurerm_container_group.this : k => g.ip_address }
}
