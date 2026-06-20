locals {
  docker_vm_count = 1
  vm_template = local.vm_templates["debian-13"]
}

module "docker_vm" {
  source = "./modules/proxmox_vm"

  name_prefix = "docker"
  vm_count = local.docker_vm_count
  tags = concat(["docker"], local.vm_template.tags)

  cores = 4
  memory_mb =  16384
  disk_size_gb = 32

  proxmox_node = var.proxmox_node
  template_vm_id = local.vm_template.id

  provision_user = local.provision.user
  provision_ssh_public_keys = local.provision.public_keys

  ansible_groups = ["docker", ]
} 

module "periphery_vm" {
 source = "./modules/proxmox_vm"

  name_prefix = "periphery"
  vm_count = local.docker_vm_count
  tags = concat(["komodo", "periphery", "docker"], local.vm_template.tags)

  cores = 4
  memory_mb =  16384
  disk_size_gb = 32

  proxmox_node = var.proxmox_node
  template_vm_id = local.vm_template.id

  provision_user = local.provision.user
  provision_ssh_public_keys = local.provision.public_keys

  ansible_groups = ["periphery", "docker"] 
}

module "komodo_vm" {
 source = "./modules/proxmox_vm"

  name_prefix = "komodo"
  vm_count = local.docker_vm_count
  tags = concat(["komodo", "docker"], local.vm_template.tags)

  cores = 2
  memory_mb =  2048
  disk_size_gb = 16

  proxmox_node = var.proxmox_node
  template_vm_id = local.vm_template.id

  provision_user = local.provision.user
  provision_ssh_public_keys = local.provision.public_keys

  ansible_groups = ["komodo", "docker"] 
}