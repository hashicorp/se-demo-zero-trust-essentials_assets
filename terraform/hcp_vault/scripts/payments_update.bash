#!/usr/bin/bash -l

export APP_HOME=/opt/hashicups/product-payments
export APP_PROPERTIES=application.properties
export DEFAULT_INSTANCE=$APP_HOME/default/$APP_PROPERTIES
export SECURE_INSTANCE=$APP_HOME/secure/$APP_PROPERTIES

# Assume we are getting VAULT_ADDR as an environment variable
export VAULT_HOST=$(echo $VAULT_ADDR | rev | cut -c6- | rev | cut -c9-)
sudo sed -i "s/VAULT_HOST/$VAULT_HOST/g" $DEFAULT_INSTANCE
sudo sed -i "s/VAULT_TOKEN/$VAULT_TOKEN/g" $DEFAULT_INSTANCE

# Assume we are getting VAULT_TOKEN as an environment variable
sudo sed -i "s/VAULT_HOST/$VAULT_HOST/g" $SECURE_INSTANCE
sudo sed -i "s/VAULT_TOKEN/$VAULT_TOKEN/g" $SECURE_INSTANCE

sudo systemctl stop hashicups-payment@default.service
sudo systemctl stop hashicups-payment@secure.service

sudo systemctl start hashicups-payment@default.service
sudo systemctl start hashicups-payment@secure.service

exit 0
