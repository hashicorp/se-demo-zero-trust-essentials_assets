#!/usr/bin/bash -l 
# Copyright IBM Corp. 2022, 2024
# SPDX-License-Identifier: MPL-2.0


# Waiting for bootstrap completion:
FILE=/tmp/bootstrap_done

# Wait for file to exist
until [ -f $FILE ]; do
    echo "Waiting for ${FILE} ..."
    sleep 2
done

# Working on hashicups-frontend first
APP_HOME=/opt/hashicups/frontend

# Wait to copy the payload for frontend
while [ ! -d "$APP_HOME" ]
do
  echo "Waiting for ${APP_HOME} ..."
  sleep 2
done

FILE=$APP_HOME/package.json

# Wait for file to exist
until [ -f $FILE ]; do
    echo "Waiting for ${FILE} ..."
    sleep 2
done

# This is temporary to ensure we can access the contents of $APP_HOME
sudo chown -R ubuntu:ubuntu $APP_HOME

# For the build environment, express the variables interactively
export NEXT_PUBLIC_PUBLIC_API_URL=http://$PUBLIC_API_NEXT_HOST:$PUBLIC_API_NEXT_PORT
export NEXT_PUBLIC_FOOTER_FLAG=HashiCups

# Move the working directory
cd $APP_HOME

# Update package.json
cp package.json original_package.json
jq --arg url "$NEXT_PUBLIC_PUBLIC_API_URL" '. + {"proxy": $url }' original_package.json > package.json
cp package.json updated_package.json
jq '.private = false' updated_package.json > package.json

# Remove no-coors options from the GQL client source in apolloClient.js
cd $APP_HOME/src/gql
sed -z 's/\n/;/g' apolloClient.js > tmp1
sed -r 's/fetchOptions:\s+\{;\s+mode:\s+.no-cors.,;\s+\},//g' tmp1 > tmp2
sed -z 's/;/\n/g' tmp2 > apolloClient.js
rm -f tmp1 tmp2

# Build the app
cd $APP_HOME
yarn build

# Inject the public API URL in the .next scripts.
find $APP_HOME/.next \( -type d -name .git -prune \) -o -type f -print0 | sudo xargs -0 sed -i "s#APP_NEXT_PUBLIC_API_URL#$NEXT_PUBLIC_PUBLIC_API_URL#g"
find $APP_HOME/.next \( -type d -name .git -prune \) -o -type f -print0 | sudo xargs -0 sed -i "s#APP_PUBLIC_FOOTER_FLAG#$NEXT_PUBLIC_FOOTER_FLAG#g"

# Revert to intended ownership combo
sudo chown -R nextjs:nodejs $APP_HOME

# Wait for HashiCups frontend service
SERVICE=/usr/lib/systemd/system/hashicups-frontend.service

until [ -f "$SERVICE" ]; do
  echo "Waiting for ${SERVICE} to be ready."
  sleep 2
done

# Create service depedency here:
cat << EOF > /tmp/local.conf
[Service]
Environment="NEXT_PUBLIC_PUBLIC_API_URL=${NEXT_PUBLIC_PUBLIC_API_URL}"
EOF

sudo mv /tmp/local.conf /etc/systemd/system/hashicups-frontend.service.d/.
sudo systemctl daemon-reexec
sudo systemctl daemon-reload

# Wait for the bootstrap process to complete for nginx
APP_HOME=/etc/nginx/sites-available

# Ensure the service is ready
SERVICE=/usr/lib/systemd/system/nginx.service

until [ -f "$SERVICE" ]; do
  echo "Waiting for ${SERVICE} to be ready."
  sleep 2
done

sudo cp /home/ubuntu/nginx_default $APP_HOME/default
sudo sed -i "s/PUBLIC_API_HOST/$PUBLIC_API_HOST/g" $APP_HOME/default
sudo sed -i "s/PUBLIC_API_PORT/$PUBLIC_API_PORT/g" $APP_HOME/default
sudo systemctl reload nginx