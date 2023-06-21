// Initial Configuration

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.61.0"
    }
  }

  backend "local" {
    path = "state/terraform.tfstate"
  }
}

provider "azurerm" {
  # Configuration options
  features {

  }
}

locals {
  location          = "East US"
  prefix            = "spoke-eastus-dev"
  resource_name     = "central"
  packer_images_rg  = "packer-images"
  vmss_upgrade_mode = "Automatic"
  ip_config_name = "default-ip-config"

  # For demo purposes.
  server_pool_credentials = {
    username = "azureadmin"
    password = "AdmiNtest7425"
  }
}

module "hub" {
  source = "./modules/hub-eastus-dev"
}

// Initial Configuration End

resource "azurerm_resource_group" "customer_rg" {
  name     = "${local.prefix}-customer-rg"
  location = local.location

  tags = {
    environment : "dev"
    type : "app"
  }
}

// Network Configuraiton
resource "azurerm_virtual_network" "spoke_vnet" {
  name                = "${local.prefix}-customer-vnet"
  location            = azurerm_resource_group.customer_rg.location
  resource_group_name = azurerm_resource_group.customer_rg.name
  address_space       = ["192.168.0.0/16"]
}

resource "azurerm_subnet" "internal_sn" {
  name                 = "${local.prefix}-internal-sn"
  resource_group_name  = azurerm_resource_group.customer_rg.name
  virtual_network_name = azurerm_virtual_network.spoke_vnet.name
  address_prefixes     = ["192.168.1.0/24"]
}

resource "azurerm_network_security_group" "vmss_nsg" {
  name                = "${local.prefix}-server-nsg"
  location            = azurerm_resource_group.customer_rg.location
  resource_group_name = azurerm_resource_group.customer_rg.name
}

resource "azurerm_network_security_rule" "allow_http" {
  name                        = "allow-http"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.vmss_nsg.name
  resource_group_name         = azurerm_network_security_group.vmss_nsg.resource_group_name
}

// Add VNet peering resources here

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "spoke-to-hub"
  resource_group_name       = azurerm_resource_group.customer_rg.name
  virtual_network_name      = azurerm_virtual_network.spoke_vnet.name
  remote_virtual_network_id = module.hub.hub_vnet_id
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "hub-to-spoke"
  resource_group_name       = module.hub.resource_group_name
  virtual_network_name      = module.hub.hub_vnet_name
  remote_virtual_network_id = azurerm_virtual_network.spoke_vnet.id
}

// End Network Configuraiton


// VMSS Deployment

resource "azurerm_linux_virtual_machine_scale_set" "pool1" {
  name                = "${local.prefix}-pool1-vmss"
  location            = azurerm_resource_group.customer_rg.location
  resource_group_name = azurerm_resource_group.customer_rg.name
  upgrade_mode        = local.vmss_upgrade_mode
  instances           = var.instance_count

  sku = var.vmss_sku

  source_image_id = "/subscriptions/${var.subscription_id}/resourceGroups/${local.packer_images_rg}/providers/Microsoft.Compute/images/nginx-image-${var.image_version}"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_username                  = local.server_pool_credentials.username
  admin_password                  = local.server_pool_credentials.password
  disable_password_authentication = false

  network_interface {
    name                      = "poo1networkprofile"
    primary                   = true
    network_security_group_id = azurerm_network_security_group.vmss_nsg.id

    ip_configuration {
      name                                         = local.ip_config_name
      primary                                      = true
      subnet_id                                    = azurerm_subnet.internal_sn.id
      application_gateway_backend_address_pool_ids = [tolist(module.hub.agw_backend_address_pool)[0].id]
    }
  }
}

resource "azurerm_linux_virtual_machine_scale_set" "pool2" {
  name                = "${local.prefix}-pool2-vmss"
  location            = azurerm_resource_group.customer_rg.location
  resource_group_name = azurerm_resource_group.customer_rg.name
  upgrade_mode        = local.vmss_upgrade_mode
  instances           = var.instance_count
  sku                 = var.vmss_sku

  source_image_id = "/subscriptions/${var.subscription_id}/resourceGroups/${local.packer_images_rg}/providers/Microsoft.Compute/images/nginx-image-${var.image_version}"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_username                  = local.server_pool_credentials.username
  admin_password                  = local.server_pool_credentials.password
  disable_password_authentication = false

  network_interface {
    name                      = "pool2networkprofile"
    primary                   = true
    network_security_group_id = azurerm_network_security_group.vmss_nsg.id

    ip_configuration {
      name                                         = local.ip_config_name
      primary                                      = true
      subnet_id                                    = azurerm_subnet.internal_sn.id
      application_gateway_backend_address_pool_ids = [tolist(module.hub.agw_backend_address_pool)[1].id]
    }
  }
}
