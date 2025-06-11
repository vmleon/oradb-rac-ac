data "oci_core_vcn" "db_vcn" {
  vcn_id = var.vcn_ocid
}

data "oci_core_subnet" "db_subnet" {
  subnet_id = var.subnet_ocid
}