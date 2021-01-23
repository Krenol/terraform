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
    name = "web-rg"
    location = "Germany West Central"
}