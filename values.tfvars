local_network_gateways = {
  LNG1 = {
    name          = "LNG1"
    location      = "Central US"
    gateway_ip    = "203.0.113.1"
    address_space = ["192.168.1.0/24"]
  }
  LNG2 = {
    name          = "LNG2"
    location      = "Central US"
    gateway_ip    = "203.0.113.2"
    address_space = ["192.168.2.0/24"]
  }
}

vpn_shared_keys = "SuperSecretSharedKey123!"