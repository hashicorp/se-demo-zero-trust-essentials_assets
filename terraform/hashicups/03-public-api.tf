resource "null_resource" "configure-public-api" {
  depends_on = [
    aws_db_instance.products,
    aws_instance.hashicups_products_api,
    aws_instance.hashicups_public_api
  ]

  provisioner "file" {
    source      = "scripts/public_auth.bash"
    destination = "/home/ubuntu/public_auth.bash"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("./private.key")
      host        = aws_instance.hashicups_public_api[0].public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod u+x /home/ubuntu/public_auth.bash",
      "PRODUCT_API_IP=\"${aws_instance.hashicups_products_api[0].public_ip}\" /home/ubuntu/public_auth.bash",
      "sudo systemctl start hashicups-public-api",
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("./private.key")
      host        = aws_instance.hashicups_public_api[0].public_ip
    }
  }
}
