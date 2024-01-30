# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

module "hashicups" {
  source = "./hashicups"
}

module "hcp" {
  source = "./hcp"
  # Required to start building HCP HVN, Vault and Consul 
  vpc_id                = module.hashicups.aws_vpc_id
  vpc_region            = module.hashicups.aws_vpc_region
  hvn_region            = module.hashicups.aws_vpc_region
  public_route_table_id = module.hashicups.aws_route_table_id
  public_subnet         = module.hashicups.aws_public_subnet_id
  security_group_id     = module.hashicups.aws_ec2_security_group_id
}

module "hcp_post" {
  source                = "./hcp_post"
  hvn_id                = module.hcp.hvn_id
  vpc_id                = module.hashicups.aws_vpc_id
  vpc_region            = module.hashicups.aws_vpc_region
  public_route_table_id = module.hashicups.aws_route_table_id
}

module "hcp_vault" {
  source                    = "./hcp_vault"
  address                   = module.hcp.vault_public_endpoint_url
  namespace                 = module.hcp.vault_namespace
  token                     = module.hcp.vault_admin_token.token
  product_database_username = module.hashicups.db_user
  product_database_address  = module.hashicups.product_database_address
  product_database_password = module.hashicups.db_password
  target_ec2_attributes     = module.hashicups.target_ec2_attributes
}

module "hcp_boundary" {
  source = "./hcp_boundary"

  # User-provided 
  controller_url            = var.controller_url
  auth_method_id            = var.auth_method_id
  bootstrap_user_login_name = var.bootstrap_user_login_name
  bootstrap_user_password   = var.bootstrap_user_password

  # Derived 
  name                 = module.hcp.hvn_id
  vault_db_secret_path = module.hcp_vault.database_secret_path
  vault_token          = module.hcp_vault.vault_token_for_boundary_credentials_store
  vault_address        = module.hcp.vault_public_endpoint_url
  vault_namespace      = module.hcp.vault_namespace
  target_ec2           = module.hashicups.target_ec2_attributes
  target_db            = module.hashicups.target_db
}

module "hcp_consul" {
  source                = "./hcp_consul"
  address               = module.hcp.consul_url
  datacenter            = module.hcp.consul_datacenter
  token                 = module.hcp.consul_root_token
  target_ec2_unique     = module.hashicups.target_ec2
  target_ec2_attributes = module.hashicups.target_ec2_attributes
}
