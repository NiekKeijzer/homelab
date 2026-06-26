variable "hostname" {
  type        = string
  description = "Hostname used in the OS configuration (ct_config) and ignition filename."
}

variable "vm_name" {
  type        = string
  description = "Name of the VM in Proxmox (used for the VM resource and data VM)."
}

variable "bu_content" {
  type        = string
  description = "Rendered Butane (.bu) content to convert to Ignition."
}

variable "base_tags" {
  type        = list(string)
  description = "Base tags applied to all VMs."
}

variable "role_tag" {
  type        = string
  description = "Role-specific tag applied to the main VM."
}

variable "cpu_cores" {
  type = number
}

variable "memory" {
  type = number
}

variable "data_disk_size" {
  type    = number
  default = 32
}

variable "boot_disk_size" {
  type    = number
  default = 16
}

variable "flatcar_image_id" {
  type        = string
  description = "File ID of the Flatcar image in Proxmox."
}

variable "proxmox_node" {
  type = string
}

variable "proxmox_snippets_datastore_id" {
  type = string
}
