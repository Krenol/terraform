terraform {
  required_providers {
    azure = {
      source  = "azurerm"
      version = "~> 2.43.0"
    }
    rand = {
      source  = "random"
      version = "~> 3.0.0"
    }
  }
}

provider "azure" {
  features {

  }
}

provider "rand" {

}

module "location_west_de" {
  source = "./location"

  web_server_location      = "Germany West Central"
  web_server_rg            = "${var.web_server_rg}-gwc"
  resource_prefix          = "${var.resource_prefix}-gwc"
  web_server_address_space = "1.0.0.0/22"
  web_server_name          = var.web_server_name
  environment              = var.environment
  web_server_count         = var.web_server_count
  web_server_subnets = {
    web-server           = "1.0.1.0/24"
    azure-bastion-subnet = "1.0.2.0/24"
  }
  terraform_script_version = var.terraform_script_version
}


module "location_west_eu" {
  source = "./location"

  web_server_location      = "West Europe"
  web_server_rg            = "${var.web_server_rg}-weu"
  resource_prefix          = "${var.resource_prefix}-weu"
  web_server_address_space = "2.0.0.0/22"
  web_server_name          = var.web_server_name
  environment              = var.environment
  web_server_count         = var.web_server_count
  web_server_subnets = {
    web-server           = "2.0.1.0/24"
    azure-bastion-subnet = "2.0.2.0/24"
  }
  terraform_script_version = var.terraform_script_version
}
