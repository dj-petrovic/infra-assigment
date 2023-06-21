# Deploy resource group. 

locals {
  prefix        = "hub-eastus-dev"
  resource_name = "central"
  location      = "East US"

  server_pool_1             = "server-pool-1"
  server_pool_2             = "server-pool-2"
  fronted_ip_config         = "frontend-ip-configuration"
  default_http_setting_name = "default-http-setting"
  default_listener_name     = "default-http-listener"
  request_routing_rule_name = "default-url-path-map"

}

resource "azurerm_resource_group" "hub_rg" {
  name     = "${local.prefix}-infra-rg"
  location = local.location

  tags = {
    environment : "dev"
    type : "infra"
  }
}

# Networking configuraiton

resource "azurerm_virtual_network" "hub_vnet" {
  name                = "${local.prefix}-${local.resource_name}-vnet"
  location            = azurerm_resource_group.hub_rg.location
  resource_group_name = azurerm_resource_group.hub_rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "appgw" {
  name                 = "${local.prefix}-agw-sn"
  resource_group_name  = azurerm_resource_group.hub_rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

resource "azurerm_public_ip" "centrallb_pip" {
  name                = "${local.prefix}-${local.resource_name}-pip"
  location            = azurerm_resource_group.hub_rg.location
  resource_group_name = azurerm_resource_group.hub_rg.name
  allocation_method   = "Dynamic"
}

## End networking configuration
resource "azurerm_application_gateway" "central_agw" {
  name                = "${local.prefix}-${local.resource_name}-agw"
  location            = azurerm_resource_group.hub_rg.location
  resource_group_name = azurerm_resource_group.hub_rg.name

  sku {
    name = var.sku.name
    tier = var.sku.tier
    capacity = var.sku.capacity 
  }

  gateway_ip_configuration {
    name      = "gateway-ipconfig"
    subnet_id = azurerm_subnet.appgw.id
  }

  frontend_port {
    name = "port-80"
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.fronted_ip_config
    public_ip_address_id = azurerm_public_ip.centrallb_pip.id
  }

  backend_address_pool {
    name = local.server_pool_1
  }

  backend_address_pool {
    name = local.server_pool_2
  }

  backend_http_settings {
    name                  = local.default_http_setting_name
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 1
  }

  http_listener {
    name                           = local.default_http_setting_name
    frontend_ip_configuration_name = local.fronted_ip_config
    frontend_port_name             = "port-80"
    protocol                       = "Http"
  }

  url_path_map {
    name = local.request_routing_rule_name

    default_backend_address_pool_name  = local.server_pool_1
    default_backend_http_settings_name = local.default_http_setting_name

    path_rule {
      name = "page1-rule"

      paths                      = ["/page1.html"]
      backend_address_pool_name  = local.server_pool_1
      backend_http_settings_name = local.default_http_setting_name
    }
    path_rule {
      name = "page2-rule"

      paths                      = ["/page2.html"]
      backend_address_pool_name  = local.server_pool_2
      backend_http_settings_name = local.default_http_setting_name

    }
  }

  request_routing_rule {
    name = "my-request-routing-rule"

    rule_type = "PathBasedRouting"

    http_listener_name = local.default_http_setting_name

    url_path_map_name = local.request_routing_rule_name

  }
}

