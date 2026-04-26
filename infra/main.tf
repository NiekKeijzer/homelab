resource "tls_private_key" "provision_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_sensitive_file" "provision_ssh_key" {
  filename = "${var.generated_files}/id_rsa"
  content  = tls_private_key.provision_ssh_key.private_key_openssh
}

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
    public_key = chomp(tls_private_key.provision_ssh_key.public_key_openssh)
    private_key_path = abspath(local_sensitive_file.provision_ssh_key.filename)
  }
}