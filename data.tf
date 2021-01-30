data "azurerm_key_vault" "key_vault" {
  name                = "private-data-terraform"
  resource_group_name = "remote-state"
}


data "azurerm_key_vault_secret" "ssh_pub_key" {
  name         = "ssh"
  key_vault_id = data.azurerm_key_vault.key_vault.id
}
