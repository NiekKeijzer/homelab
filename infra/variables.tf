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

variable "proxmox_iso_datastore_id" {
  default = "iso-store"
}

variable "proxmox_snippets_datastore_id" {
  default = "snippet-store"
}

variable "proxmox_node" {
  default = "pve-01"
}

variable "cidr" {
  default = "192.168.20.0/24"
}

variable "gateway" {
  type = string
  default = "192.168.20.1"
}

variable "dns" {
  type = list(string)
  default = ["192.168.20.27"]
  # default = ["192.168.20.53", "192.168.20.54"]
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

variable "github_access_token" {
  type = string
  sensitive = true
}