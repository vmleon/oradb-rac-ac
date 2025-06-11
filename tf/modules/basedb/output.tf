

locals {
  db_unique_name = oci_database_db_system.db_system.db_home[0].database[0].db_unique_name
  pdb_name = oci_database_db_system.db_system.db_home[0].database[0].pdb_name
  connection_string = oci_database_db_system.db_system.db_home[0].database[0].connection_strings[0].cdb_default
  ip_address = regex("10.0.\\d*.\\d*", oci_database_db_system.db_system.db_home[0].database[0].connection_strings[0].all_connection_strings.cdbIpDefault)
  db_pdb_conn_string = replace(local.connection_string, local.db_unique_name, local.pdb_name)
}

output "db_service" {
  value = "${var.project_name}${var.deploy_id}"
}

output "db_password" {
  value     = random_password.db_admin_password.result
  sensitive = true
}

output "db_pdb_password" {
  value     = random_password.db_pdb_password.result
  sensitive = true
}

output "db_edition" {
  value = oci_database_db_system.db_system.database_edition
}

output "db_system_id" {
  value = oci_database_db_system.db_system.id
}

output "db_home_location" {
  value = oci_database_db_system.db_system.db_home[0].db_home_location
}

output "private_ip" {
  value = local.ip_address
}

output "db_version" {
  value = oci_database_db_system.db_system.version
}

output "shape" {
  value = oci_database_db_system.db_system.shape
}

output "connection_string" {
  value = local.connection_string
}

output "pdb_connection_string" {
  value = local.db_pdb_conn_string
}
