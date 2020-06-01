output "public_ip_prefix_id" {
  description = "The id of the Public IP Prefix resource"
  value       = module.hub-firewall.public_ip_prefix_id
}

output "firewall_public_ip" {
  description = "the public ip of firewall."
  value       = module.hub-firewall.firewall_public_ip
}

output "firewall_public_ip_fqdn" {
  description = "Fully qualified domain name of the A DNS record associated with the public IP."
  value       = module.hub-firewall.firewall_public_ip_fqdn
}

output "firewall_private_ip" {
  description = "The private ip of firewall."
  value       = module.hub-firewall.firewall_private_ip
}

output "firewall_id" {
  description = "The Resource ID of the Azure Firewall."
  value       = module.hub-firewall.firewall_id
}

output "firewall_name" {
  description = "The name of the Azure Firewall."
  value       = module.hub-firewall.firewall_name
}
