terraform {
  required_providers {
    hcp = {
      source  = "hashicorp/hcp"
      version = "~> 0.40.0"
    }
  }
}

provider "hcp" {}

data "hcp_vault_cluster" "vault" {
  cluster_id = var.vault_cluster_id
}

resource "hcp_vault_cluster_admin_token" "vault" {
  cluster_id = data.hcp_vault_cluster.vault.cluster_id
}
