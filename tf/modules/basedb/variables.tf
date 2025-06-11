variable "project_name" {
  type = string
}

variable "deploy_id" {
  type = string
}

variable "region" {
  type = string
}

variable "tenancy_ocid" {
  type = string
}

variable "config_file_profile" {
  type = string
}

variable "compartment_ocid" {
  type = string
}

variable "ads" {
  type = list(any)
}

variable "vcn_ocid" {
  type = string
}

variable "subnet_ocid" {
  type = string
}

// oci db version list --compartment-id
variable "db_version" {
  default = null
  type    = string
}

variable "db_workload" {
  type    = string
  description = "OLTP, DW"
  default = "OLTP"
}

variable "db_edition" {
  type = string
  description = "STANDARD_EDITION, ENTERPRISE_EDITION, ENTERPRISE_EDITION_HIGH_PERFORMANCE, ENTERPRISE_EDITION_EXTREME_PERFORMANCE"
  default = "ENTERPRISE_EDITION_EXTREME_PERFORMANCE"
}

variable "license_model" {
  type    = string
  description = "BRING_YOUR_OWN_LICENSE, LICENSE_INCLUDED"
  default = "BRING_YOUR_OWN_LICENSE"
}

variable "whitelisted_ips" {
  type    = list(string)
  default = ["0.0.0.0/0"] # Don't do this in prod
}

variable "db_name" {
  type = string
}

variable "display_name" {
  type = string
}

variable "pdb_name" {
  type = string
}

variable "hostname" {
  type = string
}

variable "enable_auto_backup" {
  type = bool
  default = true
}

variable "ssh_public_key_content" {
  type = string
}

variable "node_count" {
  type = number
  default = 2
}

variable "cpu_core_count" {
  type    = number
  default = 4
}

variable "data_storage_size_in_gb" {
  type = number
  default = 256
}

variable "disk_redundancy" {
  type = string
  description = "NORMAL, HIGH"
  default = "HIGH"
}

variable "storage_volume_performance_mode" {
  type = string
  description = "BALANCED, HIGH_PERFORMANCE"
  default = "BALANCED"
}

variable "db_storage_management" {
  type = string
  description = "LVM, ASM"
  default = "ASM"
}

# oci db gi-version list --compartment-id XXX
# oci db system-shape list --compartment-id XXX
# oci db system-version list --compartment-id XXX --gi-version XXX --shape VM.Standard2.1
variable "shape" {
  type = string
  description = "VM.Standard.E5.Flex, VM.Standard2.1, VM.Standard2.2"
  default = "VM.Standard2.2" #  "VM.Standard2.1"
}