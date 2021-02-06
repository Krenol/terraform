resource "azurerm_resource_group" "bastion_rg" {
  name     = var.bastion_rg
  location = var.bastion_location
}

resource "azurerm_public_ip" "bastion_public_ip" {
  name                = "${var.bastion_prefix}-public-ip"
  resource_group_name = azurerm_resource_group.bastion_rg.name
  location            = var.bastion_location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion_host" {
  name                = "${var.bastion_prefix}-host"
  resource_group_name = azurerm_resource_group.bastion_rg.name
  location            = var.bastion_location

  ip_configuration {
    name                 = "${var.bastion_prefix}-gwc"
    subnet_id            = var.bastion_host_subnet
    public_ip_address_id = azurerm_public_ip.bastion_public_ip.id
  }
}
