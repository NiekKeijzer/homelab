variable "proxmox_host" {
  default = "192.168.1.178"
}

variable "proxmox_port" {
  default = 8006
  type = number
}

variable "proxmox_api_token_id" {
  type = string
}

variable "proxmox_api_token_secret" {
  sensitive = true
  type = string
}

variable "proxmox_node" {
  default = "pve01"
}

variable "gateway" {
  type = string
  default = "192.168.20.1"
}

variable "vlan_id" {
  type = number
  default = 20
}

variable "generated_files" {
  type = string
}

variable "node_domain" {
  type = string
  default = "node.burrow.casa"
}

variable "provision_user" {
  type = string
  default = "mrrobot"
}

variable "provision_ssh_public_keys" {
  type = list(string)
  sensitive = true
}