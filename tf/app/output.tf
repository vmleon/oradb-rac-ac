output "deployment" {
  value = "${local.project_name}${local.deploy_id}"
}

output "db_service" {
  value = module.basedb.db_service
}

output "db_system_id" {
  value = module.basedb.db_system_id
}

output "db_home_location" {
  value     = module.basedb.db_home_location
  sensitive = false
}

output "db_private_ip" {
  value     = module.basedb.private_ip
  sensitive = false
}

output "db_url" {
  value     = module.basedb.connection_string
  sensitive = false
}

output "db_password" {
  value     = module.basedb.db_password
  sensitive = true
}

output "db_pdb_url" {
  value     = module.basedb.pdb_connection_string
  sensitive = false
}

output "db_pdb_password" {
  value     = module.basedb.db_pdb_password
  sensitive = true
}

output "lb_ip" {
  value = oci_core_public_ip.public_reserved_ip.ip_address
}
