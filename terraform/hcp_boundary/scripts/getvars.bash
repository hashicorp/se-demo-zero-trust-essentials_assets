# Copyright IBM Corp. 2022, 2024
# SPDX-License-Identifier: MPL-2.0

 #!/bin/bash -l

export TF_VAR_target_db=$(cd /root/ec2-fast && terraform output target_db)
export TF_VAR_target_ec2=$(cd /root/ec2-fast && terraform output target_ec2)

export PGPASSWORD=$(cd /root/ec2-fast && terraform output db_password)
export PGUSERNAME=$(cd /root/ec2-fast && terraform output db_user)

export BOUNDARY_USER=$(cd /root/hcp-boundary && terraform output -raw boundary_user)
export BOUNDARY_ADDR=$(cd /root/hcp-boundary && terraform output -raw boundary_endpoint)
export BOUNDARY_PASSWORD=$(cd /root/hcp-boundary && terraform output -raw boundary_password)
export BOUNDARY_AUTH_METHOD=$(cd /root/hcp-boundary && terraform output -raw boundary_auth_method_id)
export BOUNDARY_TARGET_ID=$(cd /root/hcp-boundary && terraform output -raw boundary_target_db)

export BOUNDARY_TOKEN=$(boundary authenticate password -login-name=$BOUNDARY_USER \
    -password=$BOUNDARY_PASSWORD \
    -auth-method-id=$BOUNDARY_AUTH_METHOD \
  -keyring-type=none \
    -format=json \
  | jq -r '.item.attributes.token')
