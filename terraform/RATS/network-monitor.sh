#!/bin/bash

cd /root/terraform

TF_PUBLIC_API_HOST=$(cd /root/terraform && terraform output -json target_ec2_attributes | jq -r .public_api.ip)

ssh -i private.key -o "StrictHostKeyChecking=false" ubuntu@$TF_PUBLIC_API_HOST sudo apt install -y ngrep
ssh -t -i private.key -o "StrictHostKeyChecking=false" ubuntu@$TF_PUBLIC_API_HOST sudo ngrep -q -d eth0 "" port 8081
