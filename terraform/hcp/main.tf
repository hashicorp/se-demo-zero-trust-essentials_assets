# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

resource "random_integer" "random_id" {
  min = 100000
  max = 999999
}

locals {
  cluster_id = "${var.name_prefix}-${random_integer.random_id.result}"
  hvn_id     = "${var.name_prefix}-${random_integer.random_id.result}"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    hcp = {
      source  = "hashicorp/hcp"
      version = ">= 0.18.0"
    }
  }
}

provider "aws" {
  region = var.vpc_region
}

resource "hcp_hvn" "main" {
  hvn_id         = local.hvn_id
  cloud_provider = "aws"
  region         = var.hvn_region
  depends_on     = [var.vpc_id, var.vpc_region, var.hvn_region, var.public_subnet, var.public_route_table_id]
}

module "aws_hcp_consul" {
  source  = "hashicorp/hcp-consul/aws"
  version = "~> 0.7.2"

  hvn                = hcp_hvn.main
  vpc_id             = var.vpc_id
  subnet_ids         = [var.public_subnet]
  route_table_ids    = [var.public_route_table_id]
  security_group_ids = [var.security_group_id]
}

resource "hcp_consul_cluster" "main" {
  cluster_id      = local.cluster_id
  hvn_id          = hcp_hvn.main.hvn_id
  public_endpoint = true
  tier            = "development"
}

resource "hcp_consul_cluster_root_token" "token" {
  cluster_id = hcp_consul_cluster.main.id
}

resource "hcp_vault_cluster" "main" {
  cluster_id      = local.cluster_id
  hvn_id          = hcp_hvn.main.hvn_id
  tier            = "dev"
  public_endpoint = true
}

resource "hcp_vault_cluster_admin_token" "vault" {
  cluster_id = hcp_vault_cluster.main.cluster_id
}

resource "null_resource" "consul_client_config" {
  depends_on = [
    hcp_vault_cluster.main,
    hcp_consul_cluster.main
  ]

  provisioner "local-exec" {
    command = "echo \"${hcp_consul_cluster.main.consul_ca_file}\" | base64 --decode > client_config/ca.pem"
  }

  provisioner "local-exec" {
    command = "echo \"${hcp_consul_cluster.main.consul_config_file}\" | base64 --decode | jq > client_config/client_config.json"
  }

  provisioner "local-exec" {
    command = "echo \"${hcp_consul_cluster_root_token.token.secret_id}\" > client_config/consul_acl_token.json"
  }

  provisioner "local-exec" {
    command = "chmod 600 client_config/ca.pem"
  }
}
