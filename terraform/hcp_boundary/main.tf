terraform {
  required_providers {
    boundary = {
      source  = "hashicorp/boundary"
      version = "1.0.12"
    }
  }
}

provider "boundary" {
  addr                            = var.controller_url
  auth_method_id                  = var.auth_method_id
  password_auth_method_login_name = var.bootstrap_user_login_name
  password_auth_method_password   = var.bootstrap_user_password
}

