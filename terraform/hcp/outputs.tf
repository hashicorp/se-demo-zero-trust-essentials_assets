output "vault_admin_token" {
  sensitive = true
  value     = hcp_vault_cluster_admin_token.vault
}

output "vault_public_endpoint_url" {
  value = data.hcp_vault_cluster.vault.vault_public_endpoint_url
}

output "vault_namespace" {
  value = data.hcp_vault_cluster.vault.namespace
}
