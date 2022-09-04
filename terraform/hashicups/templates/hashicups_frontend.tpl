#!/bin/bash -l

# Required packages
curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt update
sudo apt install nodejs -y
sudo apt install npm -y
sudo apt install -y libc6 -y
curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt update
sudo apt install yarn -y
sudo apt install --no-install-recommends yarn -y
sudo apt install nginx -y
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

cd /home/ubuntu
export APP_HOME=/opt/hashicups/frontend
export APP_VERSION="1.0.5"
wget https://github.com/hashicorp-demoapp/frontend/archive/refs/tags/v$APP_VERSION.tar.gz
tar xvfz v$APP_VERSION.tar.gz
mv frontend-$APP_VERSION frontend
sudo mkdir -p /opt/hashicups
sudo mv frontend $APP_HOME

# This is temporary to ensure we can access the contents of $APP_HOME
sudo chown -R ubuntu:ubuntu $APP_HOME

# For the build environment, express the variables interactively
export NEXT_PUBLIC_PUBLIC_API_URL=
export NEXT_PUBLIC_FOOTER_FLAG=HashiCups

# Move the working directory
cd $APP_HOME
sudo npm install eslint -g -D
yarn install --frozen-lockfile --ignore-engines
yarn add --dev eslint eslint-plugin-react  --ignore-engines
#NEXT_PUBLIC_PUBLIC_API_URL=APP_NEXT_PUBLIC_API_URL NEXT_PUBLIC_FOOTER_FLAG=APP_PUBLIC_FOOTER_FLAG yarn build

# Inject the public API URL in the .next scripts.
#find $APP_HOME/.next \( -type d -name .git -prune \) -o -type f -print0 | sudo xargs -0 sed -i "s#APP_NEXT_PUBLIC_API_URL#$NEXT_PUBLIC_PUBLIC_API_URL#g"
#find $APP_HOME/.next \( -type d -name .git -prune \) -o -type f -print0 | sudo xargs -0 sed -i "s#APP_PUBLIC_FOOTER_FLAG#$NEXT_PUBLIC_FOOTER_FLAG#g"

# Administrivia
sudo addgroup --system --gid 1099 nodejs
sudo adduser --system --uid 1099 nextjs
sudo chown -R nextjs:nodejs $APP_HOME

# Service file
cat << EOF > /tmp/hashicups-frontend.service
[Unit]
Description="HashiCups Front End"
Documentation=https://github.com/hashicorp-demoapp

[Service]
User=nextjs
Group=nodejs
WorkingDirectory=/opt/hashicups/frontend
ExecStart=/opt/hashicups/frontend/node_modules/.bin/next start

[Install]
WantedBy=multi-user.target
EOF

# Stat the service file
sudo chown root:root /tmp/hashicups-frontend.service
sudo chmod 644 /tmp/hashicups-frontend.service

# This sequence is for Ubuntu Bionic 18.04
# Set up service in /etc/systemd/system.
# sudo mv /tmp/hashicups-frontend.service /etc/systemd/system
# sudo systemctl daemon-reload
# sudo systemctl enable hashicups-frontend.service
# sudo systemctl start hashicups-frontend.service 

# This sequence is for Ubuntu Focal 20.04
# Set up service in /usr/lib/systemd/system and 
# use symbolic link to /etc/systemd/system.
sudo mv /tmp/hashicups-frontend.service /usr/lib/systemd/system
sudo ln -s /usr/lib/systemd/system/hashicups-frontend.service /etc/systemd/system/hashicups-frontend.service

cat << EOF > /tmp/local.conf
[Service]
Environment="NEXT_PUBLIC_PUBLIC_API_URL="
EOF

# We need to replace the PRODUCT_API_IP later on with a remote-exec
# Then we need daemon-reexec && daemon-reload

sudo mkdir -p /etc/systemd/system/hashicups-frontend.service.d
sudo mv /tmp/local.conf /etc/systemd/system/hashicups-frontend.service.d/.
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
# sudo systemctl start hashicups-frontend 

# Configure Nginx
cat << EOF > /tmp/nginx.default
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=STATIC:10m inactive=7d use_temp_path=off;

upstream frontend_upstream {
  server localhost:3000;
}

server {
  listen 80;
  server_name  localhost;

  server_tokens off;

  gzip on;
  gzip_proxied any;
  gzip_comp_level 4;
  gzip_types text/css application/javascript image/svg+xml;

  proxy_http_version 1.1;
  proxy_set_header Upgrade \$http_upgrade;
  proxy_set_header Connection 'upgrade';
  proxy_set_header Host \$host;
  proxy_cache_bypass \$http_upgrade;

  location /_next/static {
    proxy_cache STATIC;
    proxy_pass http://frontend_upstream;

    # For testing cache - remove before deploying to production
    add_header X-Cache-Status \$upstream_cache_status;
  }

  location /static {
    proxy_cache STATIC;
    proxy_ignore_headers Cache-Control;
    proxy_cache_valid 60m;
    proxy_pass http://frontend_upstream;

    # For testing cache - remove before deploying to production
    add_header X-Cache-Status \$upstream_cache_status;
  }

  location / {
    proxy_pass http://frontend_upstream;
  }

    location /api {
    proxy_pass http://PUBLIC_API_HOST:PUBLIC_API_PORT;
  }

}
EOF

sudo cp /tmp/nginx.default /home/ubuntu/nginx_default
sudo mv /tmp/nginx.default /etc/nginx/sites-available/default
sudo systemctl reload nginx

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