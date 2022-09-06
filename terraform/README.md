HashiCups is a fictional coffee-shop application. It uses different layers to present content to the user.

| Layer       | Version | Technology   | Env |
| ----------- | ------- | ------------ | --- |
| Frontend UI | 1.0.5   | React App    | EC2 |
| Public API  | 0.0.7   | GraphQL API  | EC2 |
| Product API | 0.0.22  | GO Middlware | EC2 |
| Product DB  | 14.3    | Postgres     | RDS |
| Payments    | 0.0.16  | Spring Boot  | EC2 |
| Payments DB | latest  | Redis        | EC2 |

0- Requirements
===
Look for an HCP Service Principal Account
```bash
# These are here temporarily. We will ask
# the user to provide their unique pair with
# and explainer form. If you are doing this
# manually, then express the data as follows:
export HCP_CLIENT_SECRET=**********
export HCP_CLIENT_ID=**********
```
This scenario implies that you need to bring-your-own-boundary. The following data are required:
- controller_url
- bootstrap_user_login_name
- bootstrap_user_password
- auth_method_id

We can write this to a `terraform.auto.tfvars` file in the deployment, or we can express them as Terraform environment variables.
```bash
# terraform.auto.tfvars - HCP Boundary data
controller_url            = "https://01234556-890a-bcde-f012-3456789abcde.boundary.hashicorp.cloud"
bootstrap_user_login_name = "administrator"
bootstrap_user_password   = "correct-horse-battery-staple"
auth_method_id            = "ampw_cd3yTltIUs"
```
Or, actively as follows:
```bash
export TF_VAR_controller_url=https://01234556-890a-bcde-f012-3456789abcde.boundary.hashicorp.cloud
export TF_VAR_bootstrap_user_login_name=administrator
export TF_VAR_bootstrap_user_password=correct-horse-battery-staple
export TF_VAR_auth_method_id=ampw_cd3yTltIUs
```

1- Deploy HashiCups
===
Create a new deployment
```bash
cd /root/terraform
terraform init
terraform apply -auto-approve -target module.hashicups
```
2- Configure HCP Resources
===
We should have the HCP Service Principal credential expressed 
```bash
cd /root/terraform
terraform apply -auto-approve -target module.hcp
```
3- Post AWS -> HCP HVN Route Completion
===
```bash
terraform apply -auto-approve -target module.hcp_post
```
4- Configure HCP Vault
===
```bash
terraform apply -auto-approve -target module.hcp_vault
```
5- Configure HCP Boundary 
===
```
terraform apply -auto-approve -target module.hcp_boundary
```
6- Configure HCP Consul
===
```bash
terraform apply -auto-approve -target module.hcp_consul
```