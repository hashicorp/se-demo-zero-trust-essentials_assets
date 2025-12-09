#!/usr/bin/bash -l
# Copyright IBM Corp. 2022, 2024
# SPDX-License-Identifier: MPL-2.0


# We are expecting VAULT_ADDR, VAULT_NAMESPACE AND VAULT_TOKEN as
# inputs. We are not doing any clause checking at the moment. If
# the inputs are not there, the Vault agent fails to render secrets.

cat << EOF > /tmp/vault.env
VAULT_API_ADDR=$VAULT_ADDR
VAULT_NAMESPACE=admin
VAULT_TOKEN=$VAULT_TOKEN
EOF

cat << EOF > /tmp/vault.hcl
listener "tcp" {
  address       = "0.0.0.0:8100"
  tls_disable   = "true"
}

storage "file" {
  path = "/opt/vault/data"
}

vault {
  address="$VAULT_ADDR"
    tls_skip_verify = true
    retry {
        num_retries = 5
    }
}

auto_auth {
  method {
    type = "approle"
    config = {
      role_id_file_path = "/etc/vault.d/roleid"
      secret_id_file_path = "/etc/vault.d/secretid"
      remove_secret_id_file_after_reading = false
    }
  }

}

template {
  source = "/etc/vault.d/conf.json.ctmpl"
  destination = "/opt/hashicups/product-api-go/conf.json"
}
EOF

# Write app role id
cat << EOF > /tmp/roleid
$APPROLE_ID
EOF

# Write app role secret id
cat << EOF > /tmp/secretid
$APPROLE_SECRET_ID
EOF


# Write template file
cat << EOF > /tmp/conf_json.ctmpl
{{ with secret "hashicups/database/creds/product" }}
{
  "db_connection": "host=$DB_NAME user={{ .Data.data.username }} password={{ .Data.data.password }} dbname=products sslmode=disable",
  "bind_address": ":9090",
  "metrics_address": "localhost:9102"
}
{{ end }}
EOF

# Update configuration for Vault Agent
sudo mv /tmp/vault.hcl /etc/vault.d/vault.hcl
sudo mv /tmp/vault.env /etc/vault.d/vault.env
sudo mv /tmp/roleid /etc/vault.d/roleid
sudo mv /tmp/secretid /etc/vault.d/secretid
sudo mv /tmp/conf_json.ctmpl /etc/vault.d/conf_json.ctmpl

# Ensure we have the right owners
sudo chown --recursive vault:vault /etc/vault.d

# Enable Vault for the first time
sudo systemctl enable vault
sudo systemctl start vault
