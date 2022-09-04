#!/bin/bash -l

sudo apt update
sudo apt install build-essential -y
curl -OL https://golang.org/dl/go1.16.7.linux-amd64.tar.gz
sudo tar -C /usr/local -xvf go1.16.7.linux-amd64.tar.gz
sudo apt install jq -y

# Consul Requirements
export CONSUL_VERSION="1.13.1-1"

curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository universe -y 
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" 
sudo apt update -y
sudo UCF_FORCE_CONFFOLD=true apt upgrade -y
sudo apt install consul=$CONSUL_VERSION -y
sudo systemctl enable --now consul

export GOPATH=/usr/local/go/bin
export PATH=$PATH:$GOPATH
export APP_HOME=/opt/hashicups/public-api
export APP_VERSION="0.0.7"

cd /home/ubuntu
wget https://github.com/hashicorp-demoapp/public-api/archive/refs/tags/v$APP_VERSION.tar.gz
tar xvfz v$APP_VERSION.tar.gz
mv public-api-$APP_VERSION public-api
sudo mkdir -p /opt/hashicups
sudo mv public-api $APP_HOME

# sudo git clone https://github.com/hashicorp-demoapp/public-api.git $APP_HOME
# sudo rm -fR /opt/hashicups/public-api/.git

# This is temporary to ensure we can access the contents of $APP_HOME
sudo chown -R ubuntu:ubuntu $APP_HOME
cd $APP_HOME

sudo sed -i 's/"github.com\/docker\/docker\/daemon\/logger"//g' payments/client.go
sudo sed -i 's/logger.Info("Payment Service", "url", h.baseURL)//g' payments/client.go

# echo "export PATH=$PATH:/usr/local/go/bin" >> /etc/environment
# echo "export APP_HOME=/opt/hashicups/public_api" >> /etc/environment

cd $APP_HOME
go run scripts/gqlgen.go
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o ./bin/amd64/public-api main.go

# export AUTHN_URL=localhost:8403 
# export APP_DOMAINS=localhost 
# export DATABASE_URL=sqlite3://:memory:?mode=memory\&cache=shared 
# export SECRET_KEY_BASE='my-authn-test-secret' 
# export HTTP_AUTH_USERNAME=hello 
# export HTTP_AUTH_PASSWORD=world 

export BIND_ADDRESS=":8080"
export PRODUCT_API_URI="http://localhost:9090"
export PAYMENT_API_URI="http://localhost:18000"

# Service file
cat << EOF > /tmp/hashicups-public-api.service
[Unit]
Description="HashiCups Product API"
Documentation=https://github.com/hashicorp-demoapp

[Service]
User=ubuntu
Group=ubuntu
WorkingDirectory=$APP_HOME
ExecStart=$APP_HOME/bin/amd64/public-api

[Install]
WantedBy=multi-user.target
EOF

# This sequence is for Ubuntu Focal 20.04
# Set up service in /usr/lib/systemd/system and 
# use symbolic link to /etc/systemd/system.
sudo mv /tmp/hashicups-public-api.service /usr/lib/systemd/system
sudo ln -s /usr/lib/systemd/system/hashicups-public-api.service /etc/systemd/system/hashicups-public-api.service
sudo systemctl daemon-reexec
sudo systemctl daemon-reload 

# We need to start the service after we instantiate the
# PRODUCT_API_URI variable. That is known after the start
# of that service, so this is not a bootstrap step and is 
# completed via remote-exec later.

cat << EOF > /tmp/local.conf
[Service]
Environment="BIND_ADDRESS=:8080"
Environment="PRODUCT_API_URI=http://PRODUCT_API_HOST:PRODUCT_API_HOST"
Environment="PAYMENT_API_URI=http://PAYMENT_API_HOST:PAYMENT_API_PORT"
EOF

# We need to replace the PRODUCT_API_HOST and the PRODUCT_API_HOST, and
# the PAYMENT_API_HOST and PAYMENT_API_PORT placeholder variables later 
# with a remote-exec. Then we need daemon-reexec && daemon-reload again.

sudo mkdir -p /etc/systemd/system/hashicups-public-api.service.d
sudo mv /tmp/local.conf /etc/systemd/system/hashicups-public-api.service.d/.
sudo systemctl daemon-reexec
sudo systemctl daemon-reload

#sudo systemctl start hashicups-public-api
#sudo systemctl status hashicups-public-api

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