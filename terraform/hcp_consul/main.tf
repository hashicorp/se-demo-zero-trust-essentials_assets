variable "vpc_id" {}
variable "vpc_region" {}
variable "hvn_region" {}
variable "public_subnet" {}
variable "public_route_table_id" {}

locals {
  cluster_id = "zero-thrust"
  hvn_id     = "zero-thrust-consul"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.43"
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

provider "consul" {
  address    = hcp_consul_cluster.main.consul_public_endpoint_url
  datacenter = hcp_consul_cluster.main.datacenter
  token      = hcp_consul_cluster_root_token.token.secret_id
}

resource "hcp_hvn" "main" {
  hvn_id         = local.hvn_id
  cloud_provider = "aws"
  region         = var.hvn_region
}

module "aws_hcp_consul" {
  source  = "hashicorp/hcp-consul/aws"
  version = "~> 0.7.2"

  hvn             = hcp_hvn.main
  vpc_id          = var.vpc_id
  subnet_ids      = [var.public_subnet]
  route_table_ids = [var.public_route_table_id]
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

output "next_steps" {
  value = "Hashicups Application will be ready in ~2 minutes. Use 'terraform output consul_root_token' to retrieve the root token."
}

resource "null_resource" "consul_client_config" {
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

  provisioner "local-exec" {
    command = "tar cvfz client_config.tar.gz client_config/*"
  }
}
