resource "boundary_scope" "hashicups" {
  name                   = var.name
  scope_id               = "global"
  auto_create_admin_role = true
}

resource "boundary_scope" "cloudops" {
  name                   = "Cloud Operations"
  scope_id               = boundary_scope.hashicups.id
  auto_create_admin_role = true
}
