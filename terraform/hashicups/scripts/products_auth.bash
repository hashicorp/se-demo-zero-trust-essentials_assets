#!/usr/bin/bash -l

# Waiting for bootstrap completion:
FILE=/tmp/bootstrap_done

# Wait for file to exist
until [ -f $FILE ]; do
    echo "Waiting for ${FILE} ..."
    sleep 2
done

APP_HOME="/opt/hashicups/product-api-go"

while [ ! -d "$APP_HOME" ]
do
  echo "Waiting for ${APP_HOME} ..."
  sleep 1
done

cat << EOF > /home/ubuntu/conf.json
{
  "db_connection": "host=${POSTGRES_HOST} port=5432 user=${POSTGRES_USER} password=${POSTGRES_PASSWORD} dbname=products sslmode=disable",
  "bind_address": ":9090",
  "metrics_address": "localhost:9102"
}
EOF

sudo mv -f /home/ubuntu/conf.json $APP_HOME/.

APP_FILE=$APP_HOME/bin/amd64/product-api

if [ ! -f "$APP_FILE" ]; then
  echo "Building ${APP_FILE} ..."
  export GOPATH=/usr/local/go/bin
  export PATH=$PATH:$GOPATH
  cd $APP_HOME
  CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o $APP_FILE
fi

SERVICE=/usr/lib/systemd/system/hashicups-product-api.service

until [ -f "$SERVICE" ]; do
  echo "Waiting for ${SERVICE} to be ready."
  sleep 1
done
