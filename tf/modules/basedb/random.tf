resource "random_password" "db_admin_password" {
  length           = 16
  special          = true
  min_numeric      = 2
  min_special      = 2
  min_lower        = 3
  min_upper        = 3
  override_special = "_-#"
}

resource "random_password" "db_pdb_password" {
  length           = 16
  special          = true
  min_numeric      = 2
  min_special      = 2
  min_lower        = 3
  min_upper        = 3
  override_special = "_-#"
}