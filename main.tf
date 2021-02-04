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

module "location_gwc" {
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
  domain_name_label        = var.domain_name_label
}


module "location_weu" {
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
  domain_name_label        = var.domain_name_label
}

resource "azurerm_resource_group" "global_rg" {
  name     = "traffic-manager-rg"
  location = "West Europe"
}

resource "azurerm_traffic_manager_profile" "web_server_tm" {
  name                   = "${var.resource_prefix}-tm"
  resource_group_name    = azurerm_resource_group.global_rg.name
  traffic_routing_method = "Weighted"


  dns_config {
    relative_name = var.domain_name_label
    ttl           = 100
  }

  monitor_config {
    protocol = "http"
    port     = 80
    path     = "/"
  }
}

resource "azurerm_traffic_manager_endpoint" "web_server_gwc_ep" {
  name                = "${var.resource_prefix}-gwc-ep"
  resource_group_name = azurerm_resource_group.global_rg.name
  profile_name        = azurerm_traffic_manager_profile.web_server_tm.name
  target_resource_id  = module.location_gwc.web_server_lb_public_ip_id
  type                = "azureEndpoints"
  weight              = 100
}

resource "azurerm_traffic_manager_endpoint" "web_server_weu_ep" {
  name                = "${var.resource_prefix}-weu-ep"
  resource_group_name = azurerm_resource_group.global_rg.name
  profile_name        = azurerm_traffic_manager_profile.web_server_tm.name
  target_resource_id  = module.location_weu.web_server_lb_public_ip_id
  type                = "azureEndpoints"
  weight              = 100
}