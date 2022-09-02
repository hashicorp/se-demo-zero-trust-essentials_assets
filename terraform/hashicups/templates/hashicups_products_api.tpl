#!/bin/bash -l

# Products API requirements
sudo apt update
sudo apt install build-essential -y
curl -OL https://golang.org/dl/go1.16.7.linux-amd64.tar.gz
sudo tar -C /usr/local -xvf go1.16.7.linux-amd64.tar.gz

# Payments server requirements
sudo apt install openjdk-11-jre-headless -y
sudo apt install redis-server -y  

# Golden utility - probably the best in my 20-year career
sudo apt install jq -y

# Consul and Vault Requirements
export CONSUL_VERSION="1.13.1-1"
export VAULT_VERSION="1.11.2-1"

curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository universe -y 
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" 
sudo apt update -y
sudo UCF_FORCE_CONFFOLD=true apt upgrade -y
sudo apt install consul=$CONSUL_VERSION -y
sudo apt install vault=$VAULT_VERSION -y
sudo systemctl enable --now consul

export GOPATH=/usr/local/go/bin
export PATH=$PATH:$GOPATH
export APP_HOME=/opt/hashicups/product-api-go
export APP_VERSION="0.0.22"

cd /home/ubuntu
wget https://github.com/hashicorp-demoapp/product-api-go/archive/refs/tags/v$APP_VERSION.tar.gz
tar xvfz v$APP_VERSION.tar.gz
mv product-api-go-$APP_VERSION product-api-go
sudo mkdir -p /opt/hashicups
sudo mv product-api-go $APP_HOME

# sudo git clone https://github.com/hashicorp-demoapp/product-api-go.git $APP_HOME
# sudo rm -fR $APP_HOME/.git

# This is temporary to ensure we can access the contents of $APP_HOME
sudo chown -R ubuntu:ubuntu $APP_HOME
cd $APP_HOME

CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o ./bin/amd64/product-api

# Service unit for Hashicups Product API
cat << EOF > /tmp/hashicups-product-api.service
[Unit]
Description="HashiCups Product API"
Documentation=https://github.com/hashicorp-demoapp

[Service]
User=ubuntu
Group=ubuntu
WorkingDirectory=$APP_HOME
ExecStart=$APP_HOME/bin/amd64/product-api

[Install]
WantedBy=multi-user.target
EOF

# This sequence is for Ubuntu Focal 20.04
# Set up service in /usr/lib/systemd/system and 
# use symbolic link to /etc/systemd/system.
sudo mv /tmp/hashicups-product-api.service /usr/lib/systemd/system
sudo ln -s /usr/lib/systemd/system/hashicups-product-api.service /etc/systemd/system/hashicups-product-api.service
sudo systemctl daemon-reexec
sudo systemctl daemon-reload 

# We need to start the service after we instantiate the
# conf.json file with DB connection string. Otherwise, this:

#sudo systemctl start hashicups-product-api
#sudo systemctl status hashicups-product-api

# Doing this to by tidy.
unset APP_HOME
unset APP_VERSION

# Sequence to deploy HashiCups Payments
export APP_HOME=/opt/hashicups/product-payments
export APP_VERSION="0.0.16"

cd /home/ubuntu
wget https://github.com/hashicorp-demoapp/payments/releases/download/v$APP_VERSION/spring-boot-payments-$APP_VERSION.jar
sudo mkdir -p $APP_HOME
sudo mv spring-boot-payments-$APP_VERSION.jar $APP_HOME

# Default properties for Payments App
# Having all of the properties loaded does not
# affect the default functionality; the properties
# are required because we're overriding the default.
sudo mkdir -p $APP_HOME/default
cat << EOF > /tmp/application.properties
server.address=127.0.0.1
server.port=8081
app.storage=disabled
app.encryption.path=transit
app.encryption.key=zero-trust-payments
spring.cloud.vault.namespace=admin
spring.cloud.vault.token=VAULT_TOKEN
spring.cloud.vault.scheme=https
spring.cloud.vault.host=VAULT_HOST
spring.cloud.vault.enabled=false 
spring.redis.host=localhost
spring.redis.port=6379
app.encryption.enabled=false
EOF

sudo mv /tmp/application.properties $APP_HOME/default

# Vault properties for Payments App
export IP_ADDR=$(hostname -I | tr -d ' ')
sudo mkdir -p $APP_HOME/secure
cat << EOF > /tmp/application.properties
server.address=$IP_ADDR
server.port=8081
app.storage=redis
app.encryption.path=transit
app.encryption.key=zero-trust-payments
spring.cloud.vault.namespace=admin
spring.cloud.vault.token=VAULT_TOKEN
spring.cloud.vault.scheme=https
spring.cloud.vault.host=VAULT_HOST
spring.cloud.vault.enabled=true 
spring.redis.host=localhost
spring.redis.port=6379
app.encryption.enabled=true
EOF

sudo mv /tmp/application.properties $APP_HOME/secure

# Set Redis to use systemd
sudo sed -i 's/supervised no/supervised systemd/g' /etc/redis/redis.conf
sudo systemctl restart redis.service

# Create systemd service unit for Hashicups Payments
# Service unit for Hashicups Product API
cat << EOF > /tmp/hashicups-payment@.service
[Unit]
Description="HashiCups Payments"
Documentation=https://github.com/hashicorp-demoapp

[Service]
User=root
Group=root
WorkingDirectory=$APP_HOME
ExecStart=/usr/bin/java -jar $APP_HOME/spring-boot-payments-$APP_VERSION.jar --spring.config.location=$APP_HOME/%i/application.properties
[Install]
WantedBy=multi-user.target
EOF

sudo chown root:root /tmp/hashicups-payment@.service
sudo mv /tmp/hashicups-payment@.service /usr/lib/systemd/system/.
sudo ln -s /usr/lib/systemd/system/hashicups-payment@.service /etc/systemd/system/hashicups-payment@.service
sudo systemctl daemon-reload
sudo systemctl start hashicups-payment@default.service
sudo systemctl start hashicups-payment@secure.service

# This is the systemd service unit for Consul connect services.
# One per system and used to instantiate multiple connect links.
cat << EOF > /tmp/consul-proxy@.service
[Unit]
Description=Consul service mesh proxy for service %i
After=network.target consul.service
Requires=consul.service

[Service]
EnvironmentFile=/etc/consul.d/consul-proxy.env
Type=simple
ExecStart=/usr/bin/consul connect proxy -sidecar-for=%i
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo chown root:root /tmp/consul-proxy@.service
sudo mv /tmp/consul-proxy@.service /usr/lib/systemd/system/.
sudo ln -s /usr/lib/systemd/system/consul-proxy@.service /etc/systemd/system/consul-proxy@.service
sudo systemctl daemon-reload

echo "0" > /tmp/bootstrap_done

exit 0