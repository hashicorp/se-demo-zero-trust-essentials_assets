locals {
  payments_host_attributes = lookup(var.target_ec2_attributes, "payments", "null")
}

resource "null_resource" "vault_client_config_files" {

  provisioner "file" {
    source      = "${path.module}/scripts/payments_update.bash"
    destination = "/home/ubuntu/payments_update.bash"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("./private.key")
      host        = local.payments_host_attributes["ip"]
    }
  }
}

resource "null_resource" "vault_client_config" {
  depends_on = [
    null_resource.vault_client_config_files
  ]

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/payments_update.bash",
      "VAULT_ADDR=${var.address} VAULT_TOKEN=${vault_token.payments_transit_encryption.client_token} /home/ubuntu/payments_update.bash"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("./private.key")
      host        = local.payments_host_attributes["ip"]
    }
  }
}
