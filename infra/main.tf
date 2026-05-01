locals {
  # TODO: Keep a map of template ID 
  template_vm_id = var.proxmox_template_vm_id

  vm_templates = {
    "debian-13" = {
      id = var.proxmox_template_vm_id
      tags = ["debian", "debian-13"]
    }
  }

  provision = {
    user = var.provision_user
    public_keys = var.provision_ssh_public_keys
  }
}