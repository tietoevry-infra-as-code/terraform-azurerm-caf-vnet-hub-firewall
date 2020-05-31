output "public_ip_prefix_id" {
  description = "The id of the Public IP Prefix resource"
  value       = azurerm_public_ip_prefix.pip_prefix.id
}

output "firewall_public_ip" {
  description = "the public ip of firewall."
  value       = element(concat([for ip in azurerm_public_ip.fw-pip : ip.ip_address], [""]), 0)
}

output "firewall_public_ip_fqdn" {
  description = "Fully qualified domain name of the A DNS record associated with the public IP."
  value       = element(concat([for f in azurerm_public_ip.fw-pip : f.fqdn], [""]), 0)
}

output "firewall_private_ip" {
  description = "The private ip of firewall."
  value       = azurerm_firewall.fw.ip_configuration.0.private_ip_address
}

output "firewall_id" {
  description = "The Resource ID of the Azure Firewall."
  value       = azurerm_firewall.fw.id
}

output "firewall_name" {
  description = "The name of the Azure Firewall."
  value       = azurerm_firewall.fw.name
}
