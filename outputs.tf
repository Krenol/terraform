output "bastion_host_subnet_gwc" {
  value = module.web_app.all["gwc"].bastion_host_subnet
}
