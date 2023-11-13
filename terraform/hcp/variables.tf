# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

variable "vpc_id" {}
variable "vpc_region" {}
variable "hvn_region" {}
variable "public_subnet" {}
variable "public_route_table_id" {}
variable "security_group_id" {}

variable "name_prefix" {
  type    = string
  default = "zero-trust"
}
