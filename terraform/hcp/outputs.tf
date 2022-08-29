output "consul_root_token" {
  value     = hcp_consul_cluster_root_token.token.secret_id
  sensitive = true
}

output "consul_url" {
  value = hcp_consul_cluster.main.public_endpoint ? (
    hcp_consul_cluster.main.consul_public_endpoint_url
    ) : (
    hcp_consul_cluster.main.consul_private_endpoint_url
  )
}

output "consul_datacenter" {
  value = hcp_consul_cluster.main.datacenter
}

output "next_steps" {
  value = "Hashicups Application will be ready in ~2 minutes. Use 'terraform output consul_root_token' to retrieve the root token."
}

output "vault_admin_token" {
  sensitive = true
  value     = hcp_vault_cluster_admin_token.vault
}

output "vault_public_endpoint_url" {
  value = hcp_vault_cluster.main.vault_public_endpoint_url
}

output "vault_namespace" {
  value = hcp_vault_cluster.main.namespace
}

output "hvn_id" {
  value = hcp_hvn.main.hvn_id
}
