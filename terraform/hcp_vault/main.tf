# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.8.2"
    }
  }
}

provider "vault" {
  address   = var.address
  token     = var.token
  namespace = var.namespace
}

resource "vault_mount" "postgres" {
  path = "${var.name}/database"
  type = "database"
}

resource "vault_database_secret_backend_connection" "postgres" {
  backend       = vault_mount.postgres.path
  name          = "product"
  allowed_roles = ["*"]

  postgresql {
    connection_url = "postgresql://${var.product_database_username}:${var.product_database_password}@${var.product_database_address}:${var.product_database_port}/products?sslmode=disable"
  }
}

locals {
  products_creds_path = "${vault_mount.postgres.path}/creds/product"
}

resource "vault_database_secret_backend_role" "product" {
  backend               = vault_mount.postgres.path
  name                  = "product"
  db_name               = vault_database_secret_backend_connection.postgres.name
  creation_statements   = ["CREATE ROLE \"{{username}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO \"{{username}}\";"]
  revocation_statements = ["ALTER ROLE \"{{username}}\" NOLOGIN;"]
  default_ttl           = 604800
  max_ttl               = 604800
}

data "vault_policy_document" "product" {
  rule {
    path         = local.products_creds_path
    capabilities = ["read"]
    description  = "read all credentials for product database as product-api"
  }
}

resource "vault_policy" "product" {
  name   = "product"
  policy = data.vault_policy_document.product.hcl
}

resource "vault_auth_backend" "approle" {
  type = "approle"
}

resource "vault_approle_auth_backend_role" "agent" {
  backend        = vault_auth_backend.approle.path
  role_name      = "agent"
  token_policies = [vault_policy.boundary_controller.name, vault_policy.ssh_cred_injection.name, vault_policy.product.name]
}

resource "vault_approle_auth_backend_role_secret_id" "id" {
  backend   = vault_auth_backend.approle.path
  role_name = vault_approle_auth_backend_role.agent.role_name
}

data "local_file" "private_ssh_key" {
  filename = "./private.key"
}

resource "vault_mount" "kvv2" {
  path        = "secret"
  type        = "kv"
  options     = { version = "2" }
  description = "KV Version 2 secret engine mount"
}

resource "vault_kv_secret_v2" "ssh_secret" {
  mount               = vault_mount.kvv2.path
  name                = "my-secret"
  cas                 = 1
  delete_all_versions = true
  data_json = jsonencode(
    {
      "username"    = "ubuntu",
      "private_key" = "${data.local_file.private_ssh_key.content}"
    }
  )
}

resource "vault_kv_secret_v2" "app_secret" {
  mount               = vault_mount.kvv2.path
  name                = "my-app-secret"
  cas                 = 1
  delete_all_versions = true
  data_json = jsonencode(
    {
      "username" = "application",
      "password" = "application-password"
    }
  )
}

resource "vault_token" "boundary_credentials_store" {
  policies          = [vault_policy.boundary_controller.name, vault_policy.ssh_cred_injection.name, vault_policy.product.name]
  no_default_policy = true
  no_parent         = true
  renewable         = true
  ttl               = "120m"
  period            = "120m"
  metadata = {
    "purpose" = "boundary-credentials-library"
  }
}

resource "vault_mount" "transit" {
  path        = "transit"
  type        = "transit"
  description = "Payments API"
}

resource "vault_transit_secret_backend_key" "key" {
  backend          = vault_mount.transit.path
  name             = "zero-trust-payments"
  deletion_allowed = true
}

resource "vault_token" "payments_transit_encryption" {
  policies          = [vault_policy.hashicups_payments.name]
  no_default_policy = true
  no_parent         = true
  renewable         = true
  ttl               = "120m"
  period            = "120m"
  metadata = {
    "purpose" = "Hashicups Payments Encryption"
  }
}
