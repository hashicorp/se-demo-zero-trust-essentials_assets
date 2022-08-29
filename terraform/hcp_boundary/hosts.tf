resource "boundary_host_catalog_static" "backend_servers" {
  name        = "backend_servers"
  description = "Web servers for backend team"
  scope_id    = boundary_scope.cloudops.id
}

resource "boundary_host_static" "backend_servers" {
  for_each        = var.target_ec2
  name            = "Hashicups ${each.value.name}"
  description     = "EC2 instance ${each.value.name}"
  address         = each.value.ip
  host_catalog_id = boundary_host_catalog_static.backend_servers.id
  type            = "static"
}

resource "boundary_host_set_static" "backend_servers" {
  name            = "backend_servers"
  description     = "Host set for backend servers"
  host_catalog_id = boundary_host_catalog_static.backend_servers.id
  host_ids        = [for host in boundary_host_static.backend_servers : host.id]
  type            = "static"
}

# For database operations 
resource "boundary_host_catalog_static" "products_database" {
  name        = "products_database"
  description = "Products database"
  scope_id    = boundary_scope.cloudops.id
}

resource "boundary_host_static" "products_database" {
  for_each        = var.target_db
  name            = "products_database_${each.value}"
  description     = "products database #${each.value}"
  address         = each.key
  host_catalog_id = boundary_host_catalog_static.products_database.id
  type            = "static"
}

resource "boundary_host_set_static" "products_database" {
  name            = "products_database"
  description     = "Host set for Product Database"
  host_catalog_id = boundary_host_catalog_static.products_database.id
  host_ids        = [for host in boundary_host_static.products_database : host.id]
  type            = "static"
}

