output "database_secret_path" {
  value = local.products_creds_path
}

output "vault_token_for_boundary_credentials_store" {
  sensitive = true
  value     = vault_token.boundary_credentials_store.client_token
}
