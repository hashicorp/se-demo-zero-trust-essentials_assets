# Basic HCP Boundary configuration
This directory contains a very basic HCP deployment example for Boundary using Terraform. The goal is to teach users how to do an initial configuration via TF

## Requirements
- You need an HCP Boundary environment
- You need the latest version of Terraform and [the Boundary TF provider](https://registry.terraform.io/providers/hashicorp/boundary/latest/docs/resources/scope)
- [Boundary version 0.8.0](https://www.boundaryproject.io/downloads) or later

## Setup
- Deploy HCP Boundary
- Edit vars.tf with the following values for your environment:

You will need the following information
- *controller_url* - You can find your HCP Boundary controller url once you've enabled Boundary at https://portal.cloud.hashicorp.com/. It should be at your environment's *Boundary overview* page.
- *auth_method_id* - is the password auth method that is created by default. You can find this by logging into your Boundary environment and copying the "password" auth method ID that was created at deployment. Login -> Auth methods -> "password"
- *password_auth_method_login_name* and *password_auth_method_password* are the un and pw for the user created at deployment
- *password_auth_method_login_name* and *password_auth_method_password* - the un and pw for the user created at deployment
- *target_ips* - add in IPs for any targets you would like to onboard. Default port is 22 (which can be edited in hosts.tf)


- You can now configure via Terraform by running...
*terraform init*
*terraform plan*
*terraform apply*

- Login to your Boundary administrator portal and view the new resources that you've created

