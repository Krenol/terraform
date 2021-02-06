terraform {
  required_providers {
    rand = {
      source  = "random"
      version = "~> 3.0.0"
    }
  }
}

provider "rand" {

}

module "locations" {
  source                   = "./location"
  for_each                 = var.location_settings
  web_server_location      = each.value.location
  web_server_rg            = "${var.web_server_rg}-${each.key}"
  resource_prefix          = "${var.resource_prefix}-${each.key}"
  web_server_address_space = each.value.address_space
  web_server_name          = var.web_server_name
  environment              = var.environment
  web_server_count         = var.web_server_count
  web_server_subnets       = each.value.subnets
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

resource "azurerm_traffic_manager_endpoint" "web_server_eps" {
  for_each            = var.location_settings
  name                = "${var.resource_prefix}-${each.key}-ep"
  resource_group_name = azurerm_resource_group.global_rg.name
  profile_name        = azurerm_traffic_manager_profile.web_server_tm.name
  target_resource_id  = module.locations[each.key].web_server_lb_public_ip_id
  type                = "azureEndpoints"
  weight              = 100
}

