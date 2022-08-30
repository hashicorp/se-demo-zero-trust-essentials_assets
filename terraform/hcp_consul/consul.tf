provider "consul" {
  address    = var.address
  datacenter = var.datacenter
  token      = var.token
}

locals {
  nginx_name       = "nginx"
  frontend_name    = "frontend"
  public_api_name  = "public-api"
  product_api_name = "product-api"
}

resource "consul_config_entry" "frontend_nginx_intentions" {
  name = local.nginx_name
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Action     = "allow"
        Name       = local.frontend_name
        Precedence = 9
        Type       = "consul"
        Namespace  = "default"
      }
    ]
  })
}

resource "consul_config_entry" "public_api_intentions" {
  name = local.public_api_name
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Action     = "allow"
        Name       = local.frontend_name
        Precedence = 9
        Type       = "consul"
        Namespace  = "default"
      }
    ]
  })
}

resource "consul_config_entry" "product_api_intentions" {
  name = local.product_api_name
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Action     = "allow"
        Name       = local.public_api_name
        Precedence = 9
        Type       = "consul"
        Namespace  = "default"
      }
    ]
  })
}

resource "consul_acl_policy" "anonymous_dns_read_policy" {
  name        = "anonymous-dns-read"
  description = "Anonymous DNS Read"
  datacenters = [var.datacenter]
  rules       = <<-RULE
node_prefix "" {
  policy = "read"
}
service_prefix "" {
  policy = "read"
}
RULE
}

resource "consul_acl_token_policy_attachment" "attachment" {
  token_id = "00000000-0000-0000-0000-000000000002"
  policy   = consul_acl_policy.anonymous_dns_read_policy.name
}

resource "consul_acl_policy" "agent_policy" {
  name        = "agent-policy"
  description = "Agent Token Policy"
  datacenters = [var.datacenter]
  rules       = <<-RULE
node_prefix "" {
   policy = "write"
}
service_prefix "" {
   policy = "write"
}
RULE
}

resource "consul_acl_token" "client_token" {
  description = "Agent Token"
  policies    = ["${consul_acl_policy.agent_policy.name}"]
  local       = true
}

data "consul_acl_token_secret_id" "read" {
  accessor_id = consul_acl_token.client_token.id
}

resource "null_resource" "consul_client_data" {
  provisioner "local-exec" {
    command = "echo \"${data.consul_acl_token_secret_id.read.secret_id}\" > client_config/client_token"
  }

  provisioner "local-exec" {
    command = "tar cvfz client_config.tar.gz client_config/*"
  }

}

resource "null_resource" "consul_client_config" {
  for_each = var.target_ec2

  provisioner "file" {
    source      = "./templates/${each.value.name}.json"
    destination = "/home/ubuntu/${each.value.name}.json"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("./private.key")
      host        = each.value.ip
    }
  }

  provisioner "file" {
    source      = "./client_config.tar.gz"
    destination = "/home/ubuntu/client_config.tar.gz"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("./private.key")
      host        = each.value.ip
    }
  }

  provisioner "file" {
    source      = "./scripts/consul_client.bash"
    destination = "/home/ubuntu/consul_client.bash"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("./private.key")
      host        = each.value.ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/consul_client.bash",
      "echo | /home/ubuntu/consul_client.bash"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("./private.key")
      host        = each.value.ip
    }

  }
}
