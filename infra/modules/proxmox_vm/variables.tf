variable "name_prefix" {
  description = "Name prefix for the VM(s). VMs will be named <prefix>-01, <prefix>-02, etc."
  type        = string
}

variable "description" {
  description = "VM description shown in the Proxmox UI."
  type        = string
  default     = "Managed by OpenTofu"
}


variable "tags" {
  description = "List of tags to apply to the VMs (in addition to 'opentofu' and the name_prefix)."
  type        = list(string)
  default     = []
}

variable "vm_count" {
  description = "Number of VMs to create."
  type        = number
  default     = 1
}

variable "cores" {
  description = "Number of CPU cores per VM."
  type        = number
  default     = 2
}

variable "memory_mb" {
  description = "Dedicated RAM per VM in MB (e.g. 4096 = 4 GB, 12288 = 12 GB)."
  type        = number
  default     = 4096
}

variable "disk_size_gb" {
  description = "Root disk size in GB."
  type        = number
  default     = 20
}

variable "proxmox_node" {
  description = "Proxmox node name to deploy on."
  type        = string
}

variable "template_vm_id" {
  description = "Proxmox VM ID of the template to clone."
  type        = number
}

variable "vlan_id" {
  description = "VLAN tag for the network device."
  type        = number
  default = 20
}

variable "network_bridge" {
  description = "Proxmox network bridge."
  type        = string
  default     = "vmbr0"
}

variable "ansible_groups" {
  description = "Ansible inventory groups to add the VMs to."
  type        = list(string)
}

variable "provision_user" {
  description = "Username created by cloud-init for provisioning."
  type        = string
  default = "mrrobot"
}

variable "provision_password" {
  description = "Password for the provision user (consider using ssh keys only in production)."
  type        = string
  sensitive   = true
  default     = null
}

variable "provision_ssh_public_key" {
  description = "SSH public key added to the provision user's authorized_keys."
  type        = string
  sensitive   = true
}

variable "provision_ssh_private_key_path" {
  description = "Local path to the SSH private key used by Ansible."
  type        = string
}