variable "vault_address" {}
variable "vault_token" {}
variable "vault_db_secret_path" {}
variable "vault_namespace" {}

resource "boundary_credential_store_vault" "vault" {
  name        = "HCP Vault"
  description = "HCP Vault"
  address     = var.vault_address
  token       = var.vault_token
  scope_id    = boundary_scope.cloudops.id
  namespace   = var.vault_namespace
}

resource "boundary_credential_library_vault" "database" {
  name                = "database"
  description         = "AWS RDS Producs DB"
  credential_type     = "username_password"
  credential_store_id = boundary_credential_store_vault.vault.id
  path                = var.vault_db_secret_path
  http_method         = "GET"
}

resource "boundary_credential_library_vault" "ssh" {
  name                = "SSH"
  description         = "AWS EC2 hosts"
  credential_type     = "ssh_private_key"
  credential_store_id = boundary_credential_store_vault.vault.id
  path                = "secret/data/my-secret"
  http_method         = "GET"
}
