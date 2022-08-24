#!/bin/bash -l

sudo apt update
sudo apt install build-essential -y
curl -OL https://golang.org/dl/go1.16.7.linux-amd64.tar.gz
sudo tar -C /usr/local -xvf go1.16.7.linux-amd64.tar.gz

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

# Service file
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

sudo touch /tmp/bootstrap_done
sudo chmod 777 /tmp/bootstrap_done

echo "0" > /tmp/bootstrap_done

exit 0