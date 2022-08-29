variable "hvn_id" {}
variable "vpc_id" {}
variable "vpc_region" {}
variable "public_route_table_id" {}

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

data "hcp_hvn" "main" {
  hvn_id = var.hvn_id
}

data "hcp_aws_network_peering" "main" {
  hvn_id                = data.hcp_hvn.main.hvn_id
  peering_id            = "${var.vpc_id}-peering"
  wait_for_active_state = true
}

resource "null_resource" "post_vpc_to_hvn_routing_required" {
  provisioner "local-exec" {
    command = "aws ec2 --region $REGION create-route --route-table-id $ROUTE_TB --destination-cidr-block $DEST_CIDR --vpc-peering-connection-id $PEER_ID"

    environment = {
      REGION    = var.vpc_region
      ROUTE_TB  = var.public_route_table_id
      DEST_CIDR = data.hcp_hvn.main.cidr_block
      PEER_ID   = data.hcp_aws_network_peering.main.provider_peering_id
    }
  }
}
