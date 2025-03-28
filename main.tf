terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.23.0"
    }
  }
}

provider "azurerm" {
  subscription_id = "200275a4-ad2c-4680-8fff-0c2629e48328"
  features {}

}

resource "azurerm_resource_group" "test" {
  name     = local.resource_group_name
  location = local.location
}

resource "azurerm_virtual_network" "test_vnet" {
  name                = local.vnet_name
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name
  address_space       = local.vnet_address_space
}

resource "azurerm_subnet" "server" {
  name                 = local.subnets.server.name
  resource_group_name  = azurerm_resource_group.test.name
  virtual_network_name = azurerm_virtual_network.test_vnet.name
  address_prefixes     = [local.subnets.server.address_prefix]
}

resource "azurerm_subnet" "dmz" {
  name                 = local.subnets.dmz.name
  resource_group_name  = azurerm_resource_group.test.name
  virtual_network_name = azurerm_virtual_network.test_vnet.name
  address_prefixes     = [local.subnets.dmz.address_prefix]
}

resource "azurerm_subnet" "gateway" {
  name                 = local.subnets.gateway.name
  resource_group_name  = azurerm_resource_group.test.name
  virtual_network_name = azurerm_virtual_network.test_vnet.name
  address_prefixes     = [local.subnets.gateway.address_prefix]
}

resource "azurerm_public_ip" "nat_gateway" {
  name                = "NAT-Gateway-PIP"
  location            = local.location
  resource_group_name = local.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "nat_gw" {
  name                = "Test-NAT-Gateway"
  location            = local.location
  resource_group_name = local.resource_group_name
  sku_name            = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "nat_gw_pip" {
  nat_gateway_id       = azurerm_nat_gateway.nat_gw.id
  public_ip_address_id = azurerm_public_ip.nat_gateway.id
  depends_on           = [azurerm_nat_gateway.nat_gw, azurerm_public_ip.nat_gateway]
}

resource "azurerm_subnet_nat_gateway_association" "server_nat" {
  subnet_id      = azurerm_subnet.server.id
  nat_gateway_id = azurerm_nat_gateway.nat_gw.id
  depends_on     = [azurerm_subnet.server, azurerm_nat_gateway.nat_gw]
}

resource "azurerm_public_ip" "vng_pip" {
  name                = "VNG-PIP"
  location            = local.location
  resource_group_name = local.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_virtual_network_gateway" "vng" {
  name                = "Test-VNG"
  location            = local.location
  resource_group_name = local.resource_group_name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw1"
  active_active       = false
  enable_bgp          = false

  ip_configuration {
    name                          = "vng-ip-config"
    public_ip_address_id          = azurerm_public_ip.vng_pip.id
    subnet_id                     = azurerm_subnet.gateway.id
    private_ip_address_allocation = "Dynamic"


  }
  depends_on = [azurerm_subnet.gateway, azurerm_public_ip.vng_pip]
}

resource "azurerm_local_network_gateway" "office_lng" {
  name                = "Office-LNG"
  location            = local.location
  resource_group_name = local.resource_group_name
  gateway_address     = "12.13.14.15"
  address_space       = ["10.0.0.0/16"]
}

variable "vpn_shared_key" {
  description = "Shared key for VPN connection"
  type        = string
  sensitive   = true
}

resource "azurerm_virtual_network_gateway_connection" "site_to_site" {
  name                       = "Test-S2S-Connection"
  location                   = local.location
  resource_group_name        = local.resource_group_name
  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vng.id
  local_network_gateway_id   = azurerm_local_network_gateway.office_lng.id
  shared_key                 = var.vpn_shared_key

  ipsec_policy {
    sa_datasize      = 86400
    sa_lifetime      = 3600
    dh_group         = "DHGroup14"
    ike_encryption   = "AES256"
    ike_integrity    = "SHA256"
    ipsec_encryption = "AES256"
    ipsec_integrity  = "SHA256"
    pfs_group        = "PFS2048"

  }

  connection_mode = "Default"
  depends_on      = [azurerm_virtual_network_gateway.vng, azurerm_local_network_gateway.office_lng]
}

# Local Network Gateways
resource "azurerm_local_network_gateway" "lng1" {
  name                = local.local_network_gateways.LNG1.name
  location            = local.local_network_gateways.LNG1.location
  resource_group_name = local.resource_group_name
  gateway_address     = local.local_network_gateways.LNG1.gateway_ip
  address_space       = local.local_network_gateways.LNG1.address_space
}

resource "azurerm_local_network_gateway" "lng2" {
  name                = local.local_network_gateways.LNG2.name
  location            = local.local_network_gateways.LNG2.location
  resource_group_name = local.resource_group_name
  gateway_address     = local.local_network_gateways.LNG2.gateway_ip
  address_space       = local.local_network_gateways.LNG2.address_space
}


# VPN Connections to Local Network Gateways
resource "azurerm_virtual_network_gateway_connection" "vpn_connection_lng1" {
  name                = "VNG-to-LNG1"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name
  type                = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vng.id
  local_network_gateway_id   = azurerm_local_network_gateway.lng1.id

  shared_key = var.vpn_shared_key

    ipsec_policy {
    sa_datasize      = 86400
    sa_lifetime      = 3600
    dh_group         = "DHGroup14"
    ike_encryption   = "AES256"
    ike_integrity    = "SHA256"
    ipsec_encryption = "AES256"
    ipsec_integrity  = "SHA256"
    pfs_group        = "PFS2048"

  }

  connection_mode = "Default"
  depends_on      = [azurerm_virtual_network_gateway.vng, azurerm_local_network_gateway.lng1]
}

resource "azurerm_virtual_network_gateway_connection" "vpn_connection_lng2" {
  name                = "VNG-to-LNG2"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name
  type                = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vng.id
  local_network_gateway_id   = azurerm_local_network_gateway.lng2.id

  shared_key = var.vpn_shared_key

  
    ipsec_policy {
    sa_datasize      = 86400
    sa_lifetime      = 3600
    dh_group         = "DHGroup14"
    ike_encryption   = "AES256"
    ike_integrity    = "SHA256"
    ipsec_encryption = "AES256"
    ipsec_integrity  = "SHA256"
    pfs_group        = "PFS2048"

  }

  connection_mode = "Default"
  depends_on      = [azurerm_virtual_network_gateway.vng, azurerm_local_network_gateway.lng2]
}



 