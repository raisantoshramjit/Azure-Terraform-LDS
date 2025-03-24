locals {
  resource_group_name = "Test"
  location            = "Central US"
  vnet_name           = "Test-VNet"
  vnet_address_space  = ["10.180.170.0/23"]

  subnets = {
    server  = { name = "Server-Subnet", address_prefix = "10.180.170.0/24" }
    dmz     = { name = "DMZ-Subnet", address_prefix = "10.180.171.0/26" }
    gateway = { name = "GatewaySubnet", address_prefix = "10.180.171.64/26" }
  }

  nat_gateway_name   = "Test-NAT-Gateway"
  nat_gateway_pip    = "NAT-Gateway-PIP"
  vng_pip_name       = "VNG-PIP"
  local_network_name = "Office-LNG"

 # Local Network Gateways
  local_network_gateways = {
    LNG1 = {
      name           = "LNG1"
      location       = "Central US"
      gateway_ip     = "203.0.113.1"
      address_space  = ["192.168.1.0/24"]
    }
    LNG2 = {
      name           = "LNG2"
      location       = "Central US"
      gateway_ip     = "203.0.113.2"
      address_space  = ["192.168.2.0/24"]
    }
  }

}



