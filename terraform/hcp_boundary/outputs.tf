output "boundary_target_ec2" {
  value = boundary_target.backend_servers_ssh.id
}

output "boundary_target_db" {
  value = boundary_target.products_database_postgres.id
}

output "boundary_user" {
  value = var.bootstrap_user_login_name
}

output "boundary_password" {
  value = var.bootstrap_user_password
}

output "boundary_endpoint" {
  value = var.controller_url
}

output "boundary_auth_method_id" {
  value = var.auth_method_id
}

output "boundary_credentials_store_id" {
  value = boundary_credential_store_vault.vault.id
}
