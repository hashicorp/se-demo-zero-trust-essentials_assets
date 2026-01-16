# Copyright IBM Corp. 2022, 2024
# SPDX-License-Identifier: MPL-2.0

terraform {
  required_providers {
    boundary = {
      source  = "hashicorp/boundary"
      version = "1.1.15"
    }
  }
}

provider "boundary" {
  addr                            = var.controller_url
  auth_method_id                  = var.auth_method_id
  password_auth_method_login_name = var.bootstrap_user_login_name
  password_auth_method_password   = var.bootstrap_user_password
}

