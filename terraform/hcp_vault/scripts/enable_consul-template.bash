#!/usr/bin/bash -l
# Copyright IBM Corp. 2022, 2024
# SPDX-License-Identifier: MPL-2.0


# We are expecting VAULT_ADDR, VAULT_NAMESPACE AND VAULT_TOKEN as
# inputs. We are not doing any clause checking at the moment. If
# the inputs are not there, the Vault agent fails to render secrets.

sudo apt install consul-template -y
 
cat << EOF > /tmp/consul-template.service
[Unit]
Description=Vault consul-template

[Service]
Restart=on-failure
EnvironmentFile=-/etc/vault.d/consul-template.env
ExecStart=/usr/bin/consul-template -config /etc/vault.d/consul-template.hcl -vault-addr $VAULT_ADDR $FLAGS
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGTERM

[Install]
WantedBy=multi-user.target
EOF

sudo chown root:root /tmp/consul-template.service
sudo mv /tmp/consul-template.service /usr/lib/systemd/system/consul-template.service

cat << EOF > /tmp/consul-template.env
VAULT_API_ADDR=$VAULT_ADDR
VAULT_NAMESPACE=$VAULT_NAMESPACE
VAULT_TOKEN=$VAULT_TOKEN
EOF

sudo chown vault:vault /tmp/consul-template.env
sudo mv /tmp/consul-template.env /etc/vault.d/consul-template.env

cat << EOF > /tmp/consul-template.hcl
vault {
  retry {
    attempts = 5
    backoff = "250ms"
    max_backoff = "1m"
  }
}

template {
  source = "/etc/vault.d/product-api-db.ctmpl"
  destination = "/opt/hashicups/product-api-go/conf.json"
  exec {
    command = [ "systemctl", "restart", "hashicups-product-api.service" ]
  }
}
EOF

sudo chown vault:vault /tmp/consul-template.hcl
sudo mv /tmp/consul-template.hcl /etc/vault.d/consul-template.hcl

cat << EOF > /tmp/product-api-db.ctmpl
{{ with secret "hashicups/database/creds/product" }}
{
  "db_connection": "host=$DB_HOST port=5432 user={{.Data.username}} password={{.Data.password}} dbname=products sslmode=disable",
  "bind_address": ":9090",
  "metrics_address": "localhost:9102"
}
{{ end }}
EOF

sudo chown vault:vault /tmp/product-api-db.ctmpl
sudo mv /tmp/product-api-db.ctmpl /etc/vault.d/product-api-db.ctmpl

# After all is done here, start the consul-template service

sudo systemctl daemon-reload
sudo systemctl enable --now consul-template.service

