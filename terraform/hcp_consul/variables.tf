# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

variable "address" {}
variable "datacenter" {}
variable "token" {}
variable "target_ec2_attributes" {
  type = any
}
variable "target_ec2_unique" {
  type = any
}
