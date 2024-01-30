# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

resource "vault_policy" "ssh_cred_injection" {
  name = "kv-read"

  policy = <<EOT
path "secret/data/my-secret" {
  capabilities = ["read"]
}

path "secret/data/my-app-secret" {
  capabilities = ["read"]
}
EOT
}

resource "vault_policy" "boundary_controller" {
  name = "boundary-controller"

  policy = <<EOT
path "auth/token/lookup-self" {
capabilities = ["read"]
}

path "auth/token/renew-self" {
capabilities = ["update"]
}

path "auth/token/revoke-self" {
capabilities = ["update"]
}

path "sys/leases/renew" {
capabilities = ["update"]
}

path "sys/leases/revoke" {
capabilities = ["update"]
}

path "sys/capabilities-self" {
capabilities = ["update"]
}
EOT
}

resource "vault_policy" "hashicups_payments" {
  name = "hashicups-payments"

  policy = <<EOT
path "transit/encrypt/zero-trust-payments" {
   capabilities = [ "update" ]
}
path "transit/decrypt/zero-trust-payments" {
   capabilities = [ "update" ]
}
EOT
}
