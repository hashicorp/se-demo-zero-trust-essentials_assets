# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }

  }
}

provider "aws" {
  region = var.region
}

locals {
  availability_zones = ["${var.region}a", "${var.region}b", "${var.region}c"]
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "template_file" "hashicups_frontend" {
  template = file("${path.module}/templates/hashicups_frontend.tpl")
}

resource "aws_instance" "hashicups_frontend" {
  count                       = 1
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.main.key_name
  subnet_id                   = aws_subnet.public_subnet[count.index].id
  vpc_security_group_ids      = [aws_security_group.hashicups.id]
  associate_public_ip_address = true
  user_data                   = data.template_file.hashicups_frontend.rendered

  tags = {
    Name = "hashicups_frontend"
  }
}

data "template_file" "hashicups_public_api" {
  template = file("${path.module}/templates/hashicups_public_api.tpl")
}

resource "aws_instance" "hashicups_public_api" {
  count                       = 1
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.main.key_name
  subnet_id                   = aws_subnet.public_subnet[count.index].id
  vpc_security_group_ids      = [aws_security_group.hashicups.id]
  associate_public_ip_address = true
  user_data                   = data.template_file.hashicups_public_api.rendered

  tags = {
    Name = "hashicups_public_api"
  }
}

data "template_file" "hashicups_products_api" {
  template = file("${path.module}/templates/hashicups_products_api.tpl")
}

resource "aws_instance" "hashicups_products_api" {
  count                       = 1
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.main.key_name
  subnet_id                   = aws_subnet.public_subnet[count.index].id
  vpc_security_group_ids      = [aws_security_group.hashicups.id]
  associate_public_ip_address = true
  user_data                   = data.template_file.hashicups_products_api.rendered

  tags = {
    Name = "hashicups_product_api"
  }
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_vpc
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  count                   = length(var.public_subnets_cidr)
  cidr_block              = element(var.public_subnets_cidr, count.index)
  availability_zone       = local.availability_zones[0]
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  count                   = length(var.private_subnets_cidr)
  cidr_block              = element(var.private_subnets_cidr, count.index)
  availability_zone       = local.availability_zones[1]
  map_public_ip_on_launch = false
}

resource "aws_db_subnet_group" "db_sng" {
  name       = "hashicups-${count.index}"
  count      = length(var.public_subnets_cidr)
  subnet_ids = [aws_subnet.public_subnet[count.index].id, aws_subnet.private_subnet[count.index].id]

  tags = {
    Name = "RDS DB subnet group"
  }
}

resource "aws_route_table" "rtb_public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta_public_subnet" {
  count          = length(var.public_subnets_cidr)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.rtb_public.id
}

resource "aws_security_group" "hashicups" {
  name   = "hashicups"
  vpc_id = aws_vpc.vpc.id

  # SSH access from the VPC
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }
}

resource "aws_security_group" "database" {
  name        = "database"
  description = "Allow inbound traffic to database"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description     = "Allow inbound from products API"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.hashicups.id]
  }

  ingress {
    description = "Allow inbound from public subnets"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "tls_private_key" "main" {
  algorithm = "RSA"
}

resource "null_resource" "main" {
  provisioner "local-exec" {
    command = "echo \"${tls_private_key.main.private_key_pem}\" > private.key"
  }

  provisioner "local-exec" {
    command = "chmod 600 private.key"
  }
}

resource "aws_db_instance" "products" {
  count                  = length(var.public_subnets_cidr)
  allocated_storage      = 10
  engine                 = "postgres"
  engine_version         = "14.12"
  instance_class         = "db.t3.micro"
  db_name                = "products"
  identifier             = "products"
  username               = var.database_username
  password               = var.database_password
  db_subnet_group_name   = aws_db_subnet_group.db_sng[count.index].name
  vpc_security_group_ids = [aws_security_group.database.id]
  publicly_accessible    = true
  skip_final_snapshot    = true
  availability_zone      = local.availability_zones[0]
  tags = {
    Component = "products-db"
  }
}

resource "aws_key_pair" "main" {
  key_name   = var.key_name
  public_key = tls_private_key.main.public_key_openssh
}

