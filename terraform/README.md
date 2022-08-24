HashiCups is a fictional coffee-shop application. It uses different layers to present content to the user.

| Layer       | Version | Technology   | Env |
| ----------- | ------- | ------------ | --- |
| Frontend UI | 1.0.5   | React App    | EC2 |
| Public API  | 0.0.7   | GraphQL API  | EC2 |
| Product API | 0.0.22  | GO Middlware | EC2 |
| Product DB  | 14.3    | Postgres     | RDS |

1- Deploy HashiCups
===

Create a new deployment
```bash
cd /root/terraform
terraform init
terraform apply -auto-approve -target module.hashicups
```

2- Configure Vault
===

Look for Vault setup from HCP
```bash
# These are here temporarily. We will ask
# the user to provide their unique pair with
# and explainer form -if we use HCP Vault.
export HCP_CLIENT_SECRET=**********
export HCP_CLIENT_ID=**********
```

Obtain the data about the Vault instance
```bash
cd /root/terraform
terraform apply -auto-approve -target module.hcp
terraform apply -auto-approve -target module.hcp_vault
```

3- Configure Boundary
===

Configure Boundary
```
cd /root/terraform
terraform apply -auto-approve -target module.hcp_boundary
```

4- Configure Consul
===
Get the deployment details for VPC peering into AWS
```bash
export TF_VAR_vpc_id=$(cd /root/terraform && terraform output -raw aws_vpc_id)
export TF_VAR_vpc_region=$(cd /root/terraform && terraform output -raw aws_vpc_region)
export TF_VAR_hvn_region=$(cd /root/terraform && terraform output -raw aws_vpc_region)
export TF_VAR_public_route_table_id=$(cd /root/terraform && terraform output -raw aws_route_table_id)
export TF_VAR_public_subnet=$(cd /root/terraform && terraform output -raw aws_public_subnet_id)
```
Build the HCP Consul deployment
```bash
cd /root/terraform/hcp_consul
terraform init
terraform plan
terraform apply -auto-approve
```