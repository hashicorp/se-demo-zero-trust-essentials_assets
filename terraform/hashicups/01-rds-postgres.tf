# Copyright IBM Corp. 2022, 2024
# SPDX-License-Identifier: MPL-2.0

resource "null_resource" "configure-rds-postgres" {
  depends_on = [
    aws_db_instance.products
  ]

  provisioner "local-exec" {
    command     = "export PGPASSWORD=${var.database_password} && psql -h ${aws_db_instance.products[0].address} -U ${var.database_username} -d products -f ${path.module}/scripts/products.sql"
    interpreter = ["/usr/bin/bash", "-c"]
  }
}
