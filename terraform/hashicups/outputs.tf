# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

output "frontend_url" {
  value = "http://${aws_instance.hashicups_frontend[0].public_ip}"
}

output "frontend_ssh_string" {
  value = "ssh -i private.key ubuntu@${aws_instance.hashicups_frontend[0].public_ip}"
}

output "public_api_url" {
  value = "http://${aws_instance.hashicups_public_api[0].public_ip}:8080"
}

output "public_api_ssh_string" {
  value = "ssh -i private.key ubuntu@${aws_instance.hashicups_public_api[0].public_ip}"
}

output "products_url" {
  value = "http://${aws_instance.hashicups_products_api[0].public_ip}:9090/coffees"
}

output "product_api_ssh_string" {
  value = "ssh -i private.key ubuntu@${aws_instance.hashicups_products_api[0].public_ip}"
}

output "product_database_address" {
  value = aws_db_instance.products[0].address
}

output "target_db" {
  value = aws_db_instance.products.*.address
}

output "target_ec2" {
  value = [
    aws_instance.hashicups_frontend[0].public_ip,
    aws_instance.hashicups_public_api[0].public_ip,
    aws_instance.hashicups_products_api[0].public_ip
  ]
}

output "target_ec2_attributes" {
  sensitive = false

  value = {
    nginx       = { name = "nginx", ip = aws_instance.hashicups_frontend[0].public_ip },
    frontend    = { name = "frontend", ip = aws_instance.hashicups_frontend[0].public_ip },
    public_api  = { name = "public-api", ip = aws_instance.hashicups_public_api[0].public_ip },
    product_api = { name = "product-api", ip = aws_instance.hashicups_products_api[0].public_ip },
    payments    = { name = "payments", ip = aws_instance.hashicups_products_api[0].public_ip },
    redis       = { name = "redis", ip = aws_instance.hashicups_products_api[0].public_ip }
  }
}

output "db_password" {
  sensitive = true
  value     = aws_db_instance.products[0].password
}

output "db_user" {
  sensitive = true
  value     = aws_db_instance.products[0].username
}

output "aws_vpc_id" {
  value = aws_vpc.vpc.id
}

output "aws_route_table_id" {
  value = aws_route_table.rtb_public.id
}

output "aws_public_subnet_id" {
  value = aws_subnet.public_subnet[0].id
}

data "aws_region" "current" {}

output "aws_vpc_region" {
  value = data.aws_region.current.name
}

output "aws_ec2_security_group_id" {
  value = aws_security_group.hashicups.id
}

