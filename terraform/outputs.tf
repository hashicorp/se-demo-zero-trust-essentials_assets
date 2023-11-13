# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# HashiCups Outputs
output "frontend_url" {
  value = module.hashicups.frontend_url
}

output "frontend_ssh_string" {
  value = module.hashicups.frontend_ssh_string
}

output "public_api_url" {
  value = module.hashicups.public_api_url
}

output "public_api_ssh_string" {
  value = module.hashicups.public_api_ssh_string
}

output "products_url" {
  value = module.hashicups.products_url
}

output "product_api_ssh_string" {
  value = module.hashicups.product_api_ssh_string
}

output "product_database_address" {
  value = module.hashicups.product_database_address
}

output "target_db" {
  value = module.hashicups.target_db
}

output "target_ec2" {
  value = module.hashicups.target_ec2
}

output "target_ec2_attributes" {
  value = module.hashicups.target_ec2_attributes
}

output "db_password" {
  sensitive = true
  value     = module.hashicups.db_password
}

output "db_user" {
  sensitive = true
  value     = module.hashicups.db_user
}

output "aws_vpc_id" {
  value = module.hashicups.aws_vpc_id
}

output "aws_route_table_id" {
  value = module.hashicups.aws_route_table_id
}

output "aws_public_subnet_id" {
  value = module.hashicups.aws_public_subnet_id
}

output "aws_vpc_region" {
  value = module.hashicups.aws_vpc_region
}

# HCP - Vault-related data

output "vault_admin_token" {
  sensitive = true
  value     = module.hcp.vault_admin_token
}

output "vault_public_endpoint_url" {
  value = module.hcp.vault_public_endpoint_url
}

output "vault_namespace" {
  value = module.hcp.vault_namespace
}

output "payments_host_test" {
  value = "curl -s -X POST --header \"Content-Type: application/json\" --data '{\"name\": \"Gerry\", \"type\": \"mastercard\", \"number\": \"1234-1234-1234-1234\", \"expiry\": \"01/23\", \"cvc\": \"123\"}' ${module.hcp_vault.payments_host}:8081 | jq"
}

# Vault-specific data

output "vault_token_for_boundary_credentials_store" {
  sensitive = true
  value     = module.hcp_vault.vault_token_for_boundary_credentials_store
}

output "vault_agent_app_role_id" {
  value = module.hcp_vault.vault_agent_app_role_id
}

output "vault_agent_app_role_secret_id" {
  sensitive = true
  value     = module.hcp_vault.vault_agent_app_role_secret_id
}

# HCP Boundary data

output "boundary_target_ec2" {
  value = module.hcp_boundary.boundary_target_ec2
}

output "boundary_target_db" {
  value = module.hcp_boundary.boundary_target_db
}

output "boundary_user" {
  value = module.hcp_boundary.boundary_user
}

output "boundary_password" {
  value = module.hcp_boundary.boundary_password
}

output "boundary_endpoint" {
  value = module.hcp_boundary.boundary_endpoint
}

output "boundary_auth_method_id" {
  value = module.hcp_boundary.boundary_auth_method_id
}

output "boundary_credentials_store_id" {
  value = module.hcp_boundary.boundary_credentials_store_id
}

# Consul data

output "consul_root_token" {
  sensitive = true
  value     = module.hcp.consul_root_token
}

output "consul_url" {
  value = module.hcp.consul_url
}

output "consul_datacenter" {
  value = module.hcp.consul_datacenter
}
