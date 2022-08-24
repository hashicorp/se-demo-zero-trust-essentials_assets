resource "boundary_target" "backend_servers_ssh" {
  type                     = "tcp"
  name                     = "backend_servers_ssh"
  description              = "Backend SSH target"
  scope_id                 = boundary_scope.cloudops.id
  session_connection_limit = -1
  default_port             = 22
  host_source_ids = [
    boundary_host_set_static.backend_servers.id
  ]
  # We need to create this manually. Until the 
  # TF Boundary Provider schema implements the 
  # -credential-type flag to indicate
  # SSH private key
  # application_credential_source_ids = [
  #   boundary_credential_library_vault.ssh.id
  # ]
}

resource "boundary_target" "products_database_postgres" {
  type                     = "tcp"
  name                     = "products_database_postgres"
  description              = "Products Database Postgres Target"
  scope_id                 = boundary_scope.cloudops.id
  session_connection_limit = -1
  default_port             = 5432
  host_source_ids = [
    boundary_host_set_static.products_database.id
  ]
  application_credential_source_ids = [
    boundary_credential_library_vault.database.id
  ]
}
