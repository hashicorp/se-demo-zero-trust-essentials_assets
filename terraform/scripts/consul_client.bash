#!/bin/bash -l

cd /home/ubuntu/
tar xvfz client_config.tar.gz

cd /home/ubuntu/client_config
export CONSUL_ACL_TOKEN=$(cat /home/ubuntu/client_config/consul_acl_token.json | tr -d '\n')

jq 'del( .ca_file) | del(.verify_outgoing)' client_config.json > client.temp.1
jq --arg ca_file "/etc/consul.d/ca.pem" '. + {"tls" : { "defaults" : {"ca_file": ($ca_file), "verify_outgoing": true }}}' client.temp.1 > client.temp.2
jq --arg token "${CONSUL_ACL_TOKEN}" '.acl += {"tokens":{"agent":"\($token)"}}' client.temp.2 > client.temp.3
jq '.ports = {"grpc":8502}' client.temp.3 > client.temp.4
jq '.data_dir = "/opt/consul"' client.temp.4 > client.temp.5
jq '.bind_addr = "{{ GetInterfaceIP \"eth0\" }}"' client.temp.5 > client.temp.6
jq 'del( .ui )' client.temp.6 > client.temp.7
jq '. + {"ui_config" : {"enabled": true}}' client.temp.7 > client_config.json

rm -f client.temp*
sudo mv client_config.json /etc/consul.d/.
sudo mv ca.pem /etc/consul.d/ca.pem

cd /home/ubuntu

export CLIENT_TOKEN=$(cat /home/ubuntu/client_config/client_token | tr -d '\n')

declare -a service_files=('frontend.json' 'nginx.json' 'public-api.json' 'product-api.json' 'postgres.json')

for file in "${service_files[@]}";
do
  if [[ -f "$file" ]]
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

# We need to wait for about 10-20 seconds to avoid a race condition 
# between the Consul Agent registration and the Connect Proxy
while [[ $counter -ge 0 ]]; do
  echo "International free delay to let Consul Client bootstrap... ${counter}"
  sleep 1
  ((counter--))
done

killall screen

for file in "${service_files[@]}"; do
  if [[ -f "$file" ]]; then
    echo "Looking for service file /home/ubuntu/${file}"
    export SERVICE_NAME=$(cat "/home/ubuntu/${file}" | jq -r '.service.name')
    echo "Working on connect proxy for ${SERVICE_NAME} service..."
    screen -dm bash -c "export CONSUL_HTTP_TOKEN=$CONSUL_ACL_TOKEN && consul connect proxy -sidecar-for $SERVICE_NAME"
    echo "Done with consul connect for $SERVICE_NAME "
  fi
done

rm -fR /home/ubuntu/client_config /home/ubuntu/client_config.tar.gz

exit 0