output "bastion_host_subnet_gwc" {
  value = module.location_gwc.bastion_host_subnet
}

output "bastion_host_subnet_weu" {
  value = module.location_weu.bastion_host_subnet
}

output "web_server_lb_public_ip_id_gwc" {
  value = module.location_gwc.web_server_lb_public_ip_id
}

output "web_server_lb_public_ip_id_weu" {
  value = module.location_weu.web_server_lb_public_ip_id
}