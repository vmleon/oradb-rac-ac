resource "random_string" "deploy_id" {
  length  = 2
  special = false
  upper   = false
}

module "basedb" {
  source = "../modules/basedb"

  project_name           = local.project_name
  deploy_id              = local.deploy_id

  tenancy_ocid           = var.tenancy_ocid
  config_file_profile    = var.config_file_profile
  region                 = var.region
  compartment_ocid       = var.compartment_ocid

  ads                    = data.oci_identity_availability_domains.ads.availability_domains
  db_version             = "23.0.0.0.0"
  shape                  = var.base_db_shape
  db_name                = local.project_name
  pdb_name               = "${local.project_name}pdb"
  display_name           = "${local.project_name}${local.deploy_id}"
  hostname               = local.project_name
  ssh_public_key_content = var.ssh_public_key
  subnet_ocid            = oci_core_subnet.db_subnet.id
  vcn_ocid               = oci_core_virtual_network.vcn.id
}
