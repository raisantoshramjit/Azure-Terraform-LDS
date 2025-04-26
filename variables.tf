variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "firewall-rg"
}

variable "location" {
  description = "Azure region for deployment"
  type        = string
  default     = "Central US"
}

variable "vnet_name" {
  description = "Name of the Virtual Network"
  type        = string
  default     = "firewall-vnet"
}

variable "vnet_address_space" {
  description = "Address space for the Virtual Network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "firewall_subnet_prefix" {
  description = "Subnet prefix for Azure Firewall"
  type        = string
  default     = "10.0.1.0/24"
}

variable "firewall_mgmt_subnet_prefix" {
  description = "Subnet prefix for Azure Firewall Management"
  type        = string
  default     = "10.0.4.0/24"
}

variable "server_subnet_prefix" {
  description = "Subnet prefix for Server Subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "dmz_subnet_prefix" {
  description = "Subnet prefix for DMZ Subnet"
  type        = string
  default     = "10.0.3.0/24"
}

variable "Tunnel_subnet_prefix" {
  description = "Subnet prefix for DMZ Subnet"
  type        = string
  default     = "10.0.6.0/24"
}

variable "Gateway_subnet_prefix" {
  description = "Subnet prefix for DMZ Subnet"
  type        = string
  default     = "10.0.7.0/24"
}

variable "firewall_name" {
  description = "Name of the Azure Firewall"
  type        = string
  default     = "myAzureFirewall"
}

variable "firewall_public_ip_count" {
  description = "Number of public IPs for the firewall"
  type        = number
  default     = 1
}

variable "firewall_sku_tier" {
  description = "SKU Tier for the Azure Firewall"
  type        = string
  default     = "Basic"
}



variable "vpn_shared_keys" {
  description = "Shared key for VPN connection"
  type        = string
  sensitive   = true
}


variable "local_network_gateways" {
  description = "Map of Local Network Gateway configurations"
  type = map(object({
    name          = string
    location      = string
    gateway_ip    = string
    address_space = list(string)
  }))
}

variable "ivanti_private_ip" {
  type        = string
  description = "Ivanti VM Private IP Address"
  default     = "10.0.3.4"
}

variable "citrix_private_ip" {
  type        = string
  description = "Citrix VM Private IP Address"
  default     = "10.0.2.4"
}

variable "ivanti_public_ip" {
  type        = string
  description = "Ivanti VM Public IP Address"
  default     = "135.119.24.184"
}

variable "citrix_public_ip" {
  type        = string
  description = "Citrix VM Public IP Address"
  default     = "130.131.208.117"
}