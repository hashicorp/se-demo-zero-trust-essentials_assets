# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

variable "cidr_vpc" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnets_cidr" {
  type        = list(any)
  description = "CIDR block for Public Subnet"
  default     = ["10.0.1.0/24"]
}

variable "private_subnets_cidr" {
  type        = list(any)
  description = "CIDR block for Private Subnet"
  default     = ["10.0.10.0/24"]
}
variable "environment_tag" {
  description = "Environment tag"
  default     = "HashiCups Frontend Development"
}

variable "region" {
  description = "The region Terraform deploys the new instance"
  default     = "us-east-1"
}

variable "key_name" {
  default = "interrupt-key"
}

variable "database_username" {
  sensitive = true
  default   = "postgres"
}

variable "database_password" {
  sensitive = true
  default   = "correct-horse-battery-staple"
}

