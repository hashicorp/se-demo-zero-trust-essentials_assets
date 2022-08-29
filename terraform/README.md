HashiCups is a fictional coffee-shop application. It uses different layers to present content to the user.

| Layer       | Version | Technology   | Env |
| ----------- | ------- | ------------ | --- |
| Frontend UI | 1.0.5   | React App    | EC2 |
| Public API  | 0.0.7   | GraphQL API  | EC2 |
| Product API | 0.0.22  | GO Middlware | EC2 |
| Product DB  | 14.3    | Postgres     | RDS |


0- BYOB and HCP Service Principal Account
===
This deployment requires you to Bring-your-own-Boundary. Fill in your Boundary data in the
`terraform.auto.tfvars` for the following:
```bash
# User-provided label for HCP Boundary instance
controller_url            = "https://12345678-90ab-cdef-0123-4567890abcde.boundary.hashicorp.cloud"
bootstrap_user_login_name = "administrator"
bootstrap_user_password   = "correct-horse-battery-staple"
auth_method_id            = "ampw_LAxLrruTqX"
```

Expecting Service Principal credentials from HCP
```bash
# These are here temporarily. We will ask
# the user to provide their unique pair with
# and explainer form -if we use HCP Vault.
export HCP_CLIENT_SECRET=**********
export HCP_CLIENT_ID=**********
```

1- Deploy Step by Step
===
Create a new deployment. <o>This takes about 10-15 minutes.</o>
1- Deploy HashiCups, HCP Vault and HCP Consul
```bash
# This is our working directory
cd /root/terraform
# Apply to all modules in the deployment
terraform init
# Build AWS and HCP Resources
terraform apply -auto-approve \
-target module.hashicups \
-target module.hcp
```
2- Configure HCP Vault
```bash
terraform apply -auto-approve -target module.hcp_vault
```
3- Configure HCP Boundary
```
terraform apply -auto-approve -target module.hcp_boundary
```
4- Post AWS -> HCP HVN Route Completion
```bash
terraform apply -auto-approve -target module.hcp_post
```
5- Configure HCP Consul
```bash
terraform apply -auto-approve -target module.hcp_consul
```


2- Deploy all at once
===

Deploy the environment all at once.
```bash
# 1- Deploy HashiCups, HCP Vault and HCP Consul
# This is our working directory
cd /root/terraform
# Apply to all modules in the deployment
terraform init
# Build AWS and HCP Resources
terraform apply -auto-approve \
-target module.hashicups \
-target module.hcp
# 2- Configure HCP Vault
terraform apply -auto-approve -target module.hcp_vault
# 3- Configure HCP Boundary
terraform apply -auto-approve -target module.hcp_boundary
# 4- Post AWS -> HCP HVN Route Completion
terraform apply -auto-approve -target module.hcp_post
# 5- Configure HCP Consul
terraform apply -auto-approve -target module.hcp_consul
```