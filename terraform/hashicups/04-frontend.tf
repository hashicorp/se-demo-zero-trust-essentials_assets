resource "null_resource" "configure-frontend" {
  depends_on = [
    aws_db_instance.products,
    aws_instance.hashicups_products_api,
    aws_instance.hashicups_public_api,
    aws_instance.hashicups_frontend
  ]

  provisioner "file" {
    source      = "${path.module}/scripts/frontend_next.bash"
    destination = "/home/ubuntu/frontend_next.bash"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("./private.key")
      host        = aws_instance.hashicups_frontend[0].public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod u+x /home/ubuntu/frontend_next.bash",
      "PUBLIC_API_NEXT_HOST=${aws_instance.hashicups_public_api[0].public_ip} PUBLIC_API_NEXT_PORT=8080 PUBLIC_API_HOST=${aws_instance.hashicups_public_api[0].public_ip} PUBLIC_API_PORT=8080 /home/ubuntu/frontend_next.bash",
      "sudo systemctl restart hashicups-frontend",
      "sudo systemctl restart nginx",
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("./private.key")
      host        = aws_instance.hashicups_frontend[0].public_ip
    }
  }
}
