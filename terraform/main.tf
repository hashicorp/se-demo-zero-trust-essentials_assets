module "hashicups" {
  source = "./hashicups"
}

# export VAULT_ADDR=$(cd /root/vault/hcp && terraform output -raw vault_public_endpoint_url)
# export VAULT_TOKEN=$(cd /root/vault/hcp  && terraform output -json vault_admin_token  | jq -r '.token')
# export VAULT_NAMESPACE=$(cd /root/vault/hcp  && terraform output -raw vault_namespace)

module "hcp" {
  source           = "./hcp"
  vault_cluster_id = var.vault_cluster_id
}

# export TF_VAR_product_database_username=$(cd /root/hashicups && terraform output -raw db_user)
# export TF_VAR_product_database_address=$(cd /root/hashicups && terraform output -raw product_database_address)
# export TF_VAR_product_database_password=$(cd /root/hashicups && terraform output -raw db_password)

module "hcp_vault" {
  source                    = "./hcp_vault"
  address                   = module.hcp.vault_public_endpoint_url
  namespace                 = module.hcp.vault_namespace
  token                     = module.hcp.vault_admin_token.token
  product_database_username = module.hashicups.db_user
  product_database_address  = module.hashicups.product_database_address
  product_database_password = module.hashicups.db_password

  vault_provider_depends_on = [
    module.hcp.vault_admin_token
  ]
}

module "hcp_boundary" {
  source = "./hcp_boundary"

  # User-provided 
  controller_url            = var.controller_url
  auth_method_id            = var.auth_method_id
  bootstrap_user_login_name = var.bootstrap_user_login_name
  bootstrap_user_password   = var.bootstrap_user_password

  # Derived 
  vault_token          = module.hcp_vault.vault_token_for_boundary_credentials_store
  vault_db_secret_path = module.hcp_vault.database_secret_path
  vault_address        = module.hcp.vault_public_endpoint_url
  vault_namespace      = module.hcp.vault_namespace
  target_ec2           = module.hashicups.target_ec2
  target_db            = module.hashicups.target_db
}
