bastion_rg               = "bastion-rg"
bastion_location         = "Germany West Central"
bastion_prefix           = "bastion"
web_server_rg            = "web-rg"
resource_prefix          = "web-server"
web_server_name          = "web"
environment              = "development"
web_server_count         = 2
terraform_script_version = "1.0.0"
domain_name_label        = "gregor-lauritz-tf"

location_settings = {
  gwc = {
    location      = "Germany West Central"
    address_space = "1.0.0.0/22"
    subnets = {
      web-server         = "1.0.1.0/24"
      AzureBastionSubnet = "1.0.2.0/24"
    }
  }
  weu = {
    location      = "West Europe"
    address_space = "2.0.0.0/22"
    subnets = {
      web-server         = "2.0.1.0/24"
      AzureBastionSubnet = "2.0.2.0/24"
    }
  }
}
