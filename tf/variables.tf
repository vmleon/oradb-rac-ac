variable "tenancy_ocid" {
  type = string
}

variable "region" {
  type = string
}

variable "config_file_profile" {
  type = string
}

variable "compartment_ocid" {
  type = string
}

variable "ssh_private_key_path" {
  type = string
}

variable "ssh_public_key" {
  type = string
}

variable "project_name" {
  type    = string
  default = "dbrac"
}

variable "cert_fullchain" {
  type = string
}

variable "cert_private_key" {
  type = string
}
