resource "null_resource" "configure-product-api" {
  depends_on = [
    aws_db_instance.products,
    aws_instance.hashicups_products_api
  ]

  provisioner "file" {
    source      = "${path.module}/scripts/products_auth.bash"
    destination = "/home/ubuntu/products_auth.bash"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("./private.key")
      host        = aws_instance.hashicups_products_api[0].public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod u+x /home/ubuntu/products_auth.bash",
      "POSTGRES_HOST=\"${aws_db_instance.products[0].address}\" POSTGRES_PASSWORD=\"${var.database_password}\" POSTGRES_USER=\"${var.database_username}\" /home/ubuntu/products_auth.bash",
      "sudo systemctl start hashicups-product-api",
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("./private.key")
      host        = aws_instance.hashicups_products_api[0].public_ip
    }
  }
}
