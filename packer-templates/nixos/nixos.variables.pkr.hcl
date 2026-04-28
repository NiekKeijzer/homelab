# Proxmox VE variables for Packer templates
variable "proxmox_api_token_id" {
  type = string
}

variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
}

variable "proxmox_host" {
  type = string
}

variable "proxmox_port" {
  type = number
  default = 8006
}

variable "proxmox_node" {
  type = string
}

variable "proxmox_pool" {
  type    = string
  default = "packer-vms"
}



variable "storage_pool" {
  type    = string
  default = "local-lvm"
}

variable "iso_storage_pool" {
  type    = string
  default = "iso-store"
}


variable "iso_url" {
  type    = string
}

variable "iso_checksum" {
  type    = string
}

variable "vm_id" {
  type    = string
  default = "9101"
}

variable "vm_name" {
  type    = string
  default = "nixos-template"
}

variable "vm_tags" {
  type    = list(string)
  default = ["nixos", "template", "packer"]
}