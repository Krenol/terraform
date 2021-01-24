terraform {
  required_providers {
    azure = {
      source  = "azurerm"
      version = "~> 2.2.0"
    }
  }
}

provider "azure" {
  features {

  }
}

resource "azurerm_resource_group" "webserver_server_rg" {
  name     = var.web_server_rg
  location = var.web_server_location
}

resource "azurerm_virtual_network" "web_server_vnet" {
  name                = "${var.resource_prefix}-vnet"
  location            = var.web_server_location
  resource_group_name = azurerm_resource_group.webserver_server_rg.name
  address_space       = [var.web_server_address_space]
}

resource "azurerm_subnet" "web_server_subnet" {
  name                 = "${var.resource_prefix}-subnet"
  resource_group_name  = azurerm_resource_group.webserver_server_rg.name
  virtual_network_name = azurerm_virtual_network.web_server_vnet.name
  address_prefix       = var.web_server_address_prefix
}

resource "azurerm_network_interface" "web_server_nic" {
  name                = "${var.web_server_name}-nic"
  location            = var.web_server_location
  resource_group_name = azurerm_resource_group.webserver_server_rg.name
  ip_configuration {
    name                          = "${var.web_server_name}-ip"
    subnet_id                     = azurerm_subnet.web_server_subnet.id
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_public_ip" "web_server_public_ip" {
  name                = "${var.resource_prefix}-public-ip"
  resource_group_name = azurerm_resource_group.webserver_server_rg.name
  location            = var.web_server_location
  allocation_method   = "Dynamic"
}
