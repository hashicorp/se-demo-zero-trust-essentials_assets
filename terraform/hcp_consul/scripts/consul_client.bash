#!/bin/bash -l

cd /home/ubuntu/
tar xvfz client_config.tar.gz

cd /home/ubuntu/client_config

export CONSUL_ACL_TOKEN=$(cat /home/ubuntu/client_config/consul_acl_token.json | tr -d '\n')
export CLIENT_TOKEN=$(cat /home/ubuntu/client_config/client_token | tr -d '\n')

# We are using a one-second delay to ensure we are able to find the files.
# The i/o tends to cause unwanted results if we do it all too quickly.
jq 'del(.ca_file) | del(.verify_outgoing) | del( .ui )' client_config.json > client.temp.1
sleep 1 && jq --arg ca_file "/etc/consul.d/ca.pem" '. + {"tls" : { "defaults" : {"ca_file": ($ca_file), "verify_outgoing": true }}}' client.temp.1 > client.temp.2
sleep 1 && jq --arg token "${CONSUL_ACL_TOKEN}" '.acl += {"tokens":{"agent":"\($token)"}}' client.temp.2 > client.temp.3
sleep 1 && jq '.ports = {"grpc":8502}' client.temp.3 > client.temp.4
sleep 1 && jq '.data_dir = "/opt/consul"' client.temp.4 > client.temp.5
sleep 1 && jq '.bind_addr = "{{ GetInterfaceIP \"eth0\" }}"' client.temp.5 > client.temp.6
sleep 1 && jq '. + {"ui_config" : {"enabled": true}}' client.temp.6 > client_config.json

# Wait for the Consul client configuration to be ready
until [ -f  /home/ubuntu/client_config/client_config.json ]; do
  sleep 1
done

# This item applies to the Consul Connect Proxy service unit
cat << EOF > consul-proxy.env
CONSUL_HTTP_TOKEN="${CLIENT_TOKEN}"
EOF

sudo mv /home/ubuntu/client_config/ca.pem /etc/consul.d/ca.pem
sudo mv /home/ubuntu/client_config/client_config.json /etc/consul.d/.
sudo mv /home/ubuntu/client_config/consul-proxy.env /etc/consul.d/.

cd /home/ubuntu

declare -a service_files=('frontend.json' 'nginx.json' 'payments.json' 'public-api.json' 'product-api.json' 'postgres.json' "redis.json")

for file in "${service_files[@]}";
do
  if [[ -f "/home/ubuntu/$file" ]]
  then
   jq --arg token "${CLIENT_TOKEN}" '.service += {"token":"\($token)"}' $file > $file.1
   sudo mv $file.1 /etc/consul.d/$file
  fi
done

sudo chown --recursive consul:consul /etc/consul.d
sudo systemctl stop consul
sudo systemctl start consul

CONSUL_SERVICE=$(sudo systemctl is-active consul)

while [ "$CONSUL_SERVICE" == "inactive" ]; do
    echo "Consul is ${CONSUL_SERVICE}. Wating for Consul Service..."
    sleep 2
    CONSUL_SERVICE=$(sudo systemctl is-active consul)
done

counter=10

# We need to delay for about 10-20 seconds to avoid a race condition 
# between the Consul Agent registration and the Consul Connect Proxy
# We do this even if the systemctl service is up and running
while [[ $counter -ge 0 ]]; do
  echo "International free delay to let Consul Client bootstrap... ${counter}"
  sleep 1
  ((counter--))
done

# Each of the named 
for file in "${service_files[@]}"; do
  if [[ -f "/etc/consul.d/$file" ]]; then
    echo "Looking for service file /etc/consul.d/${file}"
    export SERVICE_NAME=$(cat "/etc/consul.d/${file}" | jq -r '.service.name')
    echo "Working on connect proxy for ${SERVICE_NAME} service..."
    sudo systemctl stop consul-proxy@$SERVICE_NAME.service
    sudo systemctl start consul-proxy@$SERVICE_NAME.service
    echo "Done with consul connect for $SERVICE_NAME "
  fi
done

# Clean up credentials files in case we have unwanted visitors
rm -fR /home/ubuntu/client_config
rm -f /home/ubuntu/client_config.tar.gz

exit 0