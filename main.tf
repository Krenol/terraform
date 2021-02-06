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


module "web_app" {
  source                   = "./web"
  web_server_rg            = var.web_server_rg
  resource_prefix          = var.resource_prefix
  web_server_name          = var.web_server_name
  environment              = var.environment
  web_server_count         = var.web_server_count
  terraform_script_version = var.terraform_script_version
  domain_name_label        = var.domain_name_label
  location_settings        = var.location_settings
}


module "bastion" {
  source              = "./bastion"
  depends_on          = [module.web_app]
  bastion_rg          = var.bastion_rg
  bastion_location    = var.bastion_location
  bastion_prefix      = var.bastion_prefix
  bastion_host_subnet = module.web_app.all["gwc"].bastion_host_subnet
}
