terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=4.23.0"
    }
  }
}

provider "azurerm" {
  subscription_id = "200275a4-ad2c-4680-8fff-0c2629e48328"
  features {}
}

resource "azurerm_resource_group" "firewall_rg" {
  name     = "firewall-rg"
  location = var.location
}

resource "azurerm_public_ip" "firewall_pip" {
  name                = "firewall-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.firewall_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  depends_on = [azurerm_resource_group.firewall_rg]
}

resource "azurerm_public_ip" "firewall_mgmt_pip" {
  name                = "firewall-mgmt-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.firewall_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}
resource "azurerm_virtual_network" "firewall_vnet" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = azurerm_resource_group.firewall_rg.name
  address_space       = var.vnet_address_space
  depends_on = [azurerm_resource_group.firewall_rg]
}
resource "azurerm_subnet" "firewall_subnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.firewall_rg.name
  virtual_network_name = azurerm_virtual_network.firewall_vnet.name
  address_prefixes     = [var.firewall_subnet_prefix]

  depends_on = [
    azurerm_virtual_network.firewall_vnet
  ]
}

resource "azurerm_subnet" "firewall_mgmt_subnet" {
  name                 = "AzureFirewallManagementSubnet"
  resource_group_name  = azurerm_resource_group.firewall_rg.name
  virtual_network_name = azurerm_virtual_network.firewall_vnet.name
  address_prefixes     = [var.firewall_mgmt_subnet_prefix]

  depends_on = [
    azurerm_virtual_network.firewall_vnet
  ]
}


resource "azurerm_subnet" "dmz_subnet" {
  name                 = "DMZSubnet"
  resource_group_name  = azurerm_resource_group.firewall_rg.name
  virtual_network_name = azurerm_virtual_network.firewall_vnet.name
  address_prefixes     = [var.dmz_subnet_prefix]

  depends_on = [azurerm_virtual_network.firewall_vnet]
}

resource "azurerm_subnet" "server_subnet" {
  name                 = "ServerSubnet"
  resource_group_name  = azurerm_resource_group.firewall_rg.name
  virtual_network_name = azurerm_virtual_network.firewall_vnet.name
  address_prefixes     = [var.server_subnet_prefix]

  depends_on = [azurerm_virtual_network.firewall_vnet]
}


resource "azurerm_subnet" "Tunnel_subnet" {
  name                 = "TunnelSubnet"
  resource_group_name  = azurerm_resource_group.firewall_rg.name
  virtual_network_name = azurerm_virtual_network.firewall_vnet.name
  address_prefixes     = [var.Tunnel_subnet_prefix]

  depends_on = [azurerm_virtual_network.firewall_vnet]
}

resource "azurerm_subnet" "Gateway_subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.firewall_rg.name
  virtual_network_name = azurerm_virtual_network.firewall_vnet.name
  address_prefixes     = [var.Gateway_subnet_prefix]

  depends_on = [azurerm_virtual_network.firewall_vnet]
}


# Public IP for VNG
resource "azurerm_public_ip" "vng_pip" {
  name                = "vng-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  depends_on = [
    azurerm_resource_group.firewall_rg
  ]
}

# Virtual Network Gateway
resource "azurerm_virtual_network_gateway" "vng" {
  name                = "${var.resource_group_name}-vng"
  location            = var.location
  resource_group_name = var.resource_group_name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw1"
  active_active       = false
  enable_bgp          = false

  ip_configuration {
    name                          = "vng-ip-config"
    public_ip_address_id          = azurerm_public_ip.vng_pip.id
    subnet_id                     = azurerm_subnet.Gateway_subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [
    azurerm_resource_group.firewall_rg,
    azurerm_virtual_network.firewall_vnet,
    azurerm_subnet.Gateway_subnet,
    azurerm_public_ip.vng_pip
    ]
}


resource "azurerm_local_network_gateway" "lng1" {
  name                = var.local_network_gateways["LNG1"].name
  location            = var.local_network_gateways["LNG1"].location
  resource_group_name = var.resource_group_name
  gateway_address     = var.local_network_gateways["LNG1"].gateway_ip
  address_space       = var.local_network_gateways["LNG1"].address_space

  depends_on = [azurerm_resource_group.firewall_rg]
}

resource "azurerm_local_network_gateway" "lng2" {
  name                = var.local_network_gateways["LNG2"].name
  location            = var.local_network_gateways["LNG2"].location
  resource_group_name = var.resource_group_name
  gateway_address     = var.local_network_gateways["LNG2"].gateway_ip
  address_space       = var.local_network_gateways["LNG2"].address_space

  depends_on = [azurerm_resource_group.firewall_rg]
}

resource "azurerm_virtual_network_gateway_connection" "vpn_connection_lng1" {
  name                       = "VNG-to-LNG1"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vng.id
  local_network_gateway_id   = azurerm_local_network_gateway.lng1.id
  shared_key                 = var.vpn_shared_keys

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
  depends_on = [
    azurerm_virtual_network_gateway.vng,
    azurerm_local_network_gateway.lng1
  ]
}

resource "azurerm_virtual_network_gateway_connection" "vpn_connection_lng2" {
  name                       = "VNG-to-LNG2"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vng.id
  local_network_gateway_id   = azurerm_local_network_gateway.lng2.id
  shared_key                 = var.vpn_shared_keys

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
  depends_on = [
    azurerm_virtual_network_gateway.vng,
    azurerm_local_network_gateway.lng2
  ]
}

resource "azurerm_firewall" "firewall" {
  name                = var.firewall_name
  location            = var.location
  resource_group_name = azurerm_resource_group.firewall_rg.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Basic"
  threat_intel_mode   = "Alert"
  

  
  ip_configuration {
    name                      = "configuration"
    subnet_id                 = azurerm_subnet.firewall_subnet.id
    public_ip_address_id      = azurerm_public_ip.firewall_pip.id # First public IP
  }
 management_ip_configuration {
    name                 = "mgmt-configuration"
    subnet_id            = azurerm_subnet.firewall_mgmt_subnet.id
    public_ip_address_id = azurerm_public_ip.firewall_mgmt_pip.id
  }
 
   depends_on = [
    azurerm_resource_group.firewall_rg,
    azurerm_virtual_network.firewall_vnet,
    azurerm_public_ip.firewall_pip,
    azurerm_public_ip.firewall_mgmt_pip,
    azurerm_subnet.firewall_subnet,
    azurerm_subnet.firewall_mgmt_subnet
  ]
}

resource "azurerm_route_table" "server_udr" {
  name                = "server-udr"
  location            = var.location
  resource_group_name = azurerm_resource_group.firewall_rg.name

  route {
    name                   = "default-route"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
  }

  route {
    name                   = "dmz-route"
    address_prefix         = "10.0.3.0/24" # adjust this if your DMZ subnet is different
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
  }

  depends_on = [
    azurerm_resource_group.firewall_rg,
    azurerm_firewall.firewall
  ]
}

resource "azurerm_route_table" "dmz_udr" {
  name                = "dmz-udr"
  location            = var.location
  resource_group_name = azurerm_resource_group.firewall_rg.name

  route {
    name                   = "default-route"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
  }

  route {
    name                   = "server-route"
    address_prefix         = "10.0.2.0/24" # Change this if your server subnet is different
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
  }

  depends_on = [
    azurerm_resource_group.firewall_rg,
    azurerm_firewall.firewall
  ]
}

resource "azurerm_subnet_route_table_association" "server_subnet_assoc" {
  subnet_id      = azurerm_subnet.server_subnet.id
  route_table_id = azurerm_route_table.server_udr.id
  depends_on = [
    azurerm_subnet.server_subnet,
    azurerm_route_table.server_udr
  ]
}

resource "azurerm_subnet_route_table_association" "dmz_subnet_assoc" {
  subnet_id      = azurerm_subnet.dmz_subnet.id
  route_table_id = azurerm_route_table.dmz_udr.id

  depends_on = [
    azurerm_subnet.dmz_subnet,
    azurerm_route_table.dmz_udr
  ]
}

resource "azurerm_public_ip" "nat_gateway" {
  name                = "AzureFirewall-NAT-Gateway-PIP"
  location            = var.location
  resource_group_name = "firewall-rg"  # Use your actual resource group name
  allocation_method   = "Static"
  sku                 = "Standard"
  depends_on          = [azurerm_resource_group.firewall_rg]  # Ensure the correct RG resource
}

resource "azurerm_nat_gateway" "nat_gw" {
  name                = "AzureFirewall-NAT-Gateway"
  location            = var.location
  resource_group_name = "firewall-rg"  # Use your actual resource group name
  sku_name            = "Standard"
  depends_on          = [azurerm_public_ip.nat_gateway]
}

resource "azurerm_nat_gateway_public_ip_association" "nat_gw_pip" {
  nat_gateway_id       = azurerm_nat_gateway.nat_gw.id
  public_ip_address_id = azurerm_public_ip.nat_gateway.id
  depends_on           = [azurerm_nat_gateway.nat_gw, azurerm_public_ip.nat_gateway]
}

resource "azurerm_subnet_nat_gateway_association" "firewall_nat_association" {
  subnet_id      = azurerm_subnet.firewall_subnet.id
  nat_gateway_id = azurerm_nat_gateway.nat_gw.id
  depends_on     = [azurerm_subnet.firewall_subnet, azurerm_nat_gateway.nat_gw]

}


resource "azurerm_public_ip" "Citrix_public_ip" {
  name                = "Citrix-public-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.firewall_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  depends_on = [azurerm_resource_group.firewall_rg]
}

# Ivanti DNAT rules for firewall-pip
resource "azurerm_firewall_nat_rule_collection" "ivanti_dnat" {
  name                = "ivanti-dnat-collection"
  azure_firewall_name = azurerm_firewall.firewall.name
  resource_group_name = azurerm_firewall.firewall.resource_group_name
  priority            = 100
  action              = "Dnat"

  rule {
    name                   = "ivanti-port-80"
    protocols              = ["TCP", "UDP"]
    source_addresses       = ["*"]
    destination_addresses  = [azurerm_public_ip.firewall_pip.ip_address]
    destination_ports      = ["80"]
    translated_address     = var.ivanti_private_ip
    translated_port        = "80"
  }

  rule {
    name                   = "ivanti-port-443"
    protocols              = ["TCP", "UDP"]
    source_addresses       = ["*"]
    destination_addresses  = [azurerm_public_ip.firewall_pip.ip_address]
    destination_ports      = ["443"]
    translated_address     = var.ivanti_private_ip
    translated_port        = "443"
  }

  rule {
    name                   = "ivanti-port-4500"
    protocols              = ["TCP", "UDP"]
    source_addresses       = ["*"]
    destination_addresses  = [azurerm_public_ip.firewall_pip.ip_address]
    destination_ports      = ["4500"]
    translated_address     = var.ivanti_private_ip
    translated_port        = "4500"
  }

  rule {
    name                   = "ivanti-port-500"
    protocols              = ["TCP", "UDP"]
    source_addresses       = ["*"]
    destination_addresses  = [azurerm_public_ip.firewall_pip.ip_address]
    destination_ports      = ["500"]
    translated_address     = var.ivanti_private_ip
    translated_port        = "500"
  }
}

resource "azurerm_firewall_nat_rule_collection" "citrix_dnat" {
  name                = "citrix-dnat-collection"
  azure_firewall_name = azurerm_firewall.firewall.name
  resource_group_name = azurerm_firewall.firewall.resource_group_name
  priority            = 200
  action              = "Dnat"

  rule {
    name                   = "citrix-port-80"
    protocols              = ["TCP", "UDP"]
    source_addresses       = ["*"]
    destination_addresses  =  ["130.131.208.117"]
    destination_ports      = ["80"]
    translated_address     = var.citrix_private_ip
    translated_port        = "80"
  }

  rule {
    name                   = "citrix-port-443"
    protocols              = ["TCP", "UDP"]
    source_addresses       = ["*"]
    destination_addresses  = ["130.131.208.117"]
    destination_ports      = ["443"]
    translated_address     = var.citrix_private_ip
    translated_port        = "443"
  }
}

resource "azurerm_firewall_network_rule_collection" "ivanti_network" {
  name                = "ivanti-network-collection"
  azure_firewall_name = "myAzureFirewall"
  resource_group_name = "firewall-rg"
  priority            = 300
  action              = "Allow"

  rule {
    name                  = "ivanti-allow-80"
    protocols             = ["TCP", "UDP"]
    source_addresses      = ["*"]
    destination_addresses = [var.ivanti_public_ip]
    destination_ports     = ["80"]
  }

  rule {
    name                  = "ivanti-allow-443"
    protocols             = ["TCP", "UDP"]
    source_addresses      = ["*"]
    destination_addresses = [var.ivanti_public_ip]
    destination_ports     = ["443"]
  }

  rule {
    name                  = "ivanti-allow-4500"
    protocols             = ["TCP", "UDP"]
    source_addresses      = ["*"]
    destination_addresses = [var.ivanti_public_ip]
    destination_ports     = ["4500"]
  }

  rule {
    name                  = "ivanti-allow-500"
    protocols             = ["TCP", "UDP"]
    source_addresses      = ["*"]
    destination_addresses = [var.ivanti_public_ip]
    destination_ports     = ["500"]
  }
}

resource "azurerm_firewall_network_rule_collection" "citrix_network" {
  name                = "citrix-network-collection"
  azure_firewall_name = "myAzureFirewall"
  resource_group_name = "firewall-rg"
  priority            = 400
  action              = "Allow"

  rule {
    name                  = "citrix-allow-80"
    protocols             = ["TCP", "UDP"]
    source_addresses      = ["*"]
     destination_addresses = [var.citrix_public_ip]  # Using Ivanti public I
    destination_ports     = ["80"]
  }

  rule {
    name                  = "citrix-allow-443"
    protocols             = ["TCP", "UDP"]
    source_addresses      = ["*"]
    destination_addresses = [var.citrix_public_ip]  # Using Ivanti public IP
    destination_ports     = ["443"]
  }
}

resource "azurerm_firewall_network_rule_collection" "dmz-to-internal-deny" {
  name                = "dmz-to-internal-deny"
  azure_firewall_name = "myAzureFirewall"
  resource_group_name = "firewall-rg"
  priority            = 500
  action              = "Deny"

  rule {
    name                  = "dmz-to-internal-deny"
    protocols             = ["Any"]
    source_addresses      = ["10.0.3.0/24"]
    destination_addresses = ["10.0.0.0/16"]
    destination_ports     = ["*"]
  }
}

resource "azurerm_firewall_network_rule_collection" "Internal_allow_all" {
  name                = "internal-allow-all"
  azure_firewall_name = "myAzureFirewall"
  resource_group_name = "firewall-rg"
  priority            = 600
  action              = "Allow"

  rule {
    name                  = "allow-all-internal"
    protocols             = ["Any"]
    source_addresses      = ["10.0.0.0/16"]
    destination_addresses = ["10.0.0.0/16"]
    destination_ports     = ["*"]
  }
}

resource "azurerm_firewall_network_rule_collection" "outbound_allow_all" {
  name                = "outbound-allow-all"
  azure_firewall_name = "myAzureFirewall"
  resource_group_name = "firewall-rg"
  priority            = 700
  action              = "Allow"

  rule {
    name                  = "allow-all-outbound"
    protocols             = ["Any"]
    source_addresses      = ["10.0.0.0/16"]
    destination_addresses = ["*"]
    destination_ports     = ["*"]
  }
}

resource "azurerm_firewall_network_rule_collection" "deny_rfc1918" {
  name                = "deny-rfc1918"
  azure_firewall_name = "myAzureFirewall"
  resource_group_name = "firewall-rg"
  priority            = 800
  action              = "Deny"

  rule {
    name                  = "deny-private-to-private"
    protocols             = ["Any"]
    source_addresses      = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16"
    ]
    destination_addresses = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16"
    ]
    destination_ports     = ["*"]
  }
}


