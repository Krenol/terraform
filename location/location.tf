locals {
  web_server_name = var.environment == "production" ? "${var.web_server_name}-prd" : "${var.web_server_name}-dev"
  build_env       = var.environment == "production" ? "production" : "development"
}

resource "azurerm_resource_group" "webserver_server_rg" {
  name     = var.web_server_rg
  location = var.web_server_location
  tags = {
    environment = local.build_env
    version     = var.terraform_script_version
  }
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


resource "azurerm_public_ip" "web_server_lb_public_ip" {
  name                = "${var.resource_prefix}-lb-public-ip"
  resource_group_name = azurerm_resource_group.webserver_server_rg.name
  location            = var.web_server_location
  allocation_method   = var.environment == "production" ? "Static" : "Dynamic"
}

resource "azurerm_network_security_group" "web_server_nsg" {
  name                = "${var.resource_prefix}-nsg"
  resource_group_name = azurerm_resource_group.webserver_server_rg.name
  location            = var.web_server_location
}

resource "azurerm_network_security_rule" "web_server_nsg_rule_ssh" {
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

resource "azurerm_network_security_rule" "web_server_nsg_rule_http" {
  name                        = "${var.resource_prefix}-nsg-rule-http"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = "3000"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.webserver_server_rg.name
  network_security_group_name = azurerm_network_security_group.web_server_nsg.name
}

resource "azurerm_subnet_network_security_group_association" "web_server_sag" {
  network_security_group_id = azurerm_network_security_group.web_server_nsg.id
  subnet_id                 = azurerm_subnet.web_server_subnet["web-server"].id
}

resource "azurerm_linux_virtual_machine_scale_set" "web_server" {
  name                 = "${var.resource_prefix}-scale-set"
  resource_group_name  = azurerm_resource_group.webserver_server_rg.name
  location             = var.web_server_location
  upgrade_mode         = "Automatic"
  sku                  = "Standard_B1s"
  instances            = var.web_server_count
  admin_username       = "webserver"
  computer_name_prefix = local.web_server_name


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

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.storage_account.primary_blob_endpoint
  }

  network_interface {
    name    = "web_server_network_profile"
    primary = true

    ip_configuration {
      name                                   = local.web_server_name
      primary                                = true
      subnet_id                              = azurerm_subnet.web_server_subnet["web-server"].id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.web_server_lb_address_pool.id]
    }
  }
}

resource "random_string" "rnd" {
  length = 10
  upper = false
  special = false
  number = false
}


resource "azurerm_storage_account" "storage_account" {
  name                     = "bootdiags${random_string.rnd.result}"
  location                 = var.web_server_location
  resource_group_name      = azurerm_resource_group.webserver_server_rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_virtual_machine_scale_set_extension" "web_server_extension" {
  name                         = "${local.web_server_name}-extension"
  virtual_machine_scale_set_id = azurerm_linux_virtual_machine_scale_set.web_server.id
  publisher                    = "Microsoft.OSTCExtensions"
  type                         = "CustomScriptForLinux"
  type_handler_version         = "1.1"
  settings = jsonencode({
    "fileUris" : ["https://raw.githubusercontent.com/Krenol/terraform/main/exec.sh"]
    "commandToExecute" : "sh exec.sh"
  })
}


resource "azurerm_lb" "web_server_lb" {
  name                = "${var.resource_prefix}-lb"
  resource_group_name = azurerm_resource_group.webserver_server_rg.name
  location            = var.web_server_location

  frontend_ip_configuration {
    name                 = "${var.resource_prefix}-lb-frontend-ip"
    public_ip_address_id = azurerm_public_ip.web_server_lb_public_ip.id
  }
}

resource "azurerm_lb_backend_address_pool" "web_server_lb_address_pool" {
  name                = "${var.resource_prefix}-lb-address-pool"
  resource_group_name = azurerm_resource_group.webserver_server_rg.name
  loadbalancer_id     = azurerm_lb.web_server_lb.id
}

resource "azurerm_lb_probe" "web_server_lb_http_probe" {
  name                = "${var.resource_prefix}-lb-http-probe"
  resource_group_name = azurerm_resource_group.webserver_server_rg.name
  loadbalancer_id     = azurerm_lb.web_server_lb.id
  protocol            = "tcp"
  port                = 3000
}

resource "azurerm_lb_rule" "web_server_lb_http_rule" {
  name                           = "${var.resource_prefix}-lb-http-rule"
  resource_group_name            = azurerm_resource_group.webserver_server_rg.name
  loadbalancer_id                = azurerm_lb.web_server_lb.id
  protocol                       = "tcp"
  frontend_port                  = 80
  backend_port                   = 3000
  frontend_ip_configuration_name = "${var.resource_prefix}-lb-frontend-ip"
  probe_id                       = azurerm_lb_probe.web_server_lb_http_probe.id
  backend_address_pool_id        = azurerm_lb_backend_address_pool.web_server_lb_address_pool.id
}
