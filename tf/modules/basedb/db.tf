locals {
  vcn_dns_label = data.oci_core_vcn.db_vcn.dns_label != null ? data.oci_core_vcn.db_vcn.dns_label : "vcn"
  subnet_dns_label = data.oci_core_subnet.db_subnet.dns_label != null ? data.oci_core_subnet.db_subnet.dns_label : "subnet"
  
  domain_name = "${local.subnet_dns_label}.${local.vcn_dns_label}.oraclevcn.com"
}


resource "oci_database_db_system" "db_system" {
  availability_domain = lookup(var.ads[0], "name")
  compartment_id      = var.compartment_ocid
  subnet_id           = var.subnet_ocid

  cpu_core_count      = var.cpu_core_count

  database_edition    = var.db_edition

  cluster_name = "${var.hostname}"

  lifecycle {
    ignore_changes = [cpu_core_count, ssh_public_keys]
  }

  db_home {
    database {
      admin_password = random_password.db_admin_password.result
      db_name        = var.db_name
      db_workload    = var.db_workload
      pdb_name       = var.pdb_name
      character_set  = "AL32UTF8"     # Specify character set
      ncharacter_set = "AL16UTF16"    # Specify national character set
      tde_wallet_password = random_password.db_admin_password.result

      db_backup_config {
        auto_backup_enabled = var.enable_auto_backup
      }
    }

    db_version   = var.db_version
    display_name = var.display_name
  }

  disk_redundancy                 = var.disk_redundancy
  shape                           = var.shape
  ssh_public_keys                 = [var.ssh_public_key_content]
  display_name                    = var.display_name
  hostname                        = var.hostname
  data_storage_size_in_gb         = var.data_storage_size_in_gb
  storage_volume_performance_mode = var.storage_volume_performance_mode
  license_model                   = var.license_model
  node_count                      = var.node_count
  domain                          = local.domain_name

  db_system_options {
    storage_management = var.db_storage_management
  }
}


resource "time_sleep" "wait_for_db" {
  depends_on      = [oci_database_db_system.db_system]
  create_duration = "2m"
}