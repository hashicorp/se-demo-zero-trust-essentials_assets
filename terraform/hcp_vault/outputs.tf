# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

output "database_secret_path" {
  value = local.products_creds_path
}

output "vault_token_for_boundary_credentials_store" {
  sensitive = true
  value     = vault_token.boundary_credentials_store.client_token
}

output "payments_host" {
  value = local.payments_host_attributes["ip"]
}

output "vault_agent_app_role_id" {
  value = vault_approle_auth_backend_role.agent.role_id
}

output "vault_agent_app_role_secret_id" {
  sensitive = true
  value     = vault_approle_auth_backend_role_secret_id.id.secret_id
}
