terraform {
  required_providers {
    azure = {
      source  = "azurerm"
      version = "~> 2.43.0"
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
  for_each             = var.web_server_subnets
  name                 = each.key
  address_prefixes     = [each.value]
  resource_group_name  = azurerm_resource_group.webserver_server_rg.name
  virtual_network_name = azurerm_virtual_network.web_server_vnet.name
}


# resource "azurerm_subnet" "web_server_subnet" {
#   name                 = "${var.resource_prefix}-subnet"
#   resource_group_name  = azurerm_resource_group.webserver_server_rg.name
#   virtual_network_name = azurerm_virtual_network.web_server_vnet.name
#   address_prefixes     = [var.web_server_address_prefix]
# }

resource "azurerm_network_interface" "web_server_nic" {
  name                = "${var.web_server_name}-nic-${format("%02d", count.index)}"
  location            = var.web_server_location
  resource_group_name = azurerm_resource_group.webserver_server_rg.name
  count               = var.web_server_count
  ip_configuration {
    name                          = "${var.web_server_name}-ip"
    subnet_id                     = azurerm_subnet.web_server_subnet["web-server"].id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.web_server_public_ip[count.index].id
  }
}

resource "azurerm_public_ip" "web_server_public_ip" {
  name                = "${var.resource_prefix}-public-ip-${format("%02d", count.index)}"
  count               = var.web_server_count
  resource_group_name = azurerm_resource_group.webserver_server_rg.name
  location            = var.web_server_location
  allocation_method   = var.environment == "production" ? "Static" : "Dynamic"
}

resource "azurerm_network_security_group" "web_server_nsg" {
  name                = "${var.resource_prefix}-nsg"
  resource_group_name = azurerm_resource_group.webserver_server_rg.name
  location            = var.web_server_location
}

resource "azurerm_network_security_rule" "web_server_nsg_rule_rdp" {
  name                        = "${var.resource_prefix}-nsg-rule-ssh"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.webserver_server_rg.name
  network_security_group_name = azurerm_network_security_group.web_server_nsg.name
}

resource "azurerm_subnet_network_security_group_association" "web_server_sag" {
  network_security_group_id = azurerm_network_security_group.web_server_nsg.id
  subnet_id                 = azurerm_subnet.web_server_subnet["web-server"].id
}

resource "azurerm_linux_virtual_machine" "web_server" {
  name                  = "${var.web_server_name}-${format("%02d", count.index)}"
  count                 = var.web_server_count
  resource_group_name   = azurerm_resource_group.webserver_server_rg.name
  location              = var.web_server_location
  network_interface_ids = [azurerm_network_interface.web_server_nic[count.index].id]
  size                  = "Standard_B1s"
  admin_username        = "webserver"
  availability_set_id   = azurerm_availability_set.web_server_availability_set.id
  admin_ssh_key {
    username   = "webserver"
    public_key = file("~/.ssh/id_rsa.pub")
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_availability_set" "web_server_availability_set" {
  name                        = "${var.resource_prefix}-availability-set"
  resource_group_name         = azurerm_resource_group.webserver_server_rg.name
  location                    = var.web_server_location
  managed                     = true
  platform_fault_domain_count = 2
}
