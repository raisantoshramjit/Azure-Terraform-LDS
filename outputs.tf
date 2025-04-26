output "firewall_public_ips" {
  description = "List of Firewall Public IPs"
  value       = [azurerm_public_ip.firewall_pip.ip_address]  # Directly reference the single public IP
}
output "firewall_mgmt_public_ip" {
  description = "Firewall Management Public IP"
  value       = azurerm_public_ip.firewall_pip.ip_address
}
output "firewall_private_ip" {
  description = "Private IP of the Azure Firewall"
  value       = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
}

output "firewall_sku_tier" {
  description = "The SKU Tier of the deployed Azure Firewall"
  value       = var.firewall_sku_tier
}
output "vng_public_ip" {
  description = "Public IP address of the Virtual Network Gateway"
  value       = azurerm_public_ip.vng_pip.ip_address
}

output "vng_id" {
  description = "ID of the Virtual Network Gateway"
  value       = azurerm_virtual_network_gateway.vng.id
}

output "local_network_gateway_lng1_id" {
  description = "ID of Local Network Gateway 1"
  value       = azurerm_local_network_gateway.lng1.id
}

output "local_network_gateway_lng2_id" {
  description = "ID of Local Network Gateway 2"
  value       = azurerm_local_network_gateway.lng2.id
}

output "vpn_connection_lng1_id" {
  description = "ID of VPN Connection to LNG1"
  value       = azurerm_virtual_network_gateway_connection.vpn_connection_lng1.id
}

output "vpn_connection_lng2_id" {
  description = "ID of VPN Connection to LNG2"
  value       = azurerm_virtual_network_gateway_connection.vpn_connection_lng2.id
}