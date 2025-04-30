output "deployment" {
  value = "${local.project_name}${local.deploy_id}"
}

output "db_admin_password" {
  value = random_password.db_admin_password.result
  sensitive = true
}
