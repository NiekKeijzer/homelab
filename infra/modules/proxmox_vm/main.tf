resource "random_password" "provision_password" {
  length  = 16
  special = true
  override_special = "_%@"
}

resource "proxmox_virtual_environment_vm" "vm" {
  count = var.vm_count

  name        = format("%s-%02d", var.name_prefix, count.index + 1)
  description = "Managed by OpenTofu"
  tags        = distinct(concat(["opentofu", var.name_prefix], var.tags))
  node_name   = var.proxmox_node

  stop_on_destroy = true

  agent {
    enabled = true
  }

  clone {
    vm_id = var.template_vm_id
  }

  cpu {
    cores = var.cores
  }

  memory {
    dedicated = var.memory_mb
  }

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_account {
      username = var.provision_user
      password = random_password.provision_password.result
      keys     = [chomp(var.provision_ssh_public_key)]
    }
  }

  disk {
    size      = var.disk_size_gb
    interface = "virtio0"
    iothread  = true
    discard   = "on"
  }

  network_device {
    bridge  = var.network_bridge
    vlan_id = var.vlan_id
    model   = "virtio"
  }

  operating_system {
    type = "l26"
  }
}

resource "ansible_host" "vm" {
  depends_on = [proxmox_virtual_environment_vm.vm]

  count = var.vm_count

  name   = proxmox_virtual_environment_vm.vm[count.index].name
  groups = var.ansible_groups

  variables = {
    ansible_host                 = proxmox_virtual_environment_vm.vm[count.index].ipv4_addresses[1][0]
    ansible_user                 = var.provision_user
    ansible_ssh_private_key_file = var.provision_ssh_private_key_path

    ipv6_address = proxmox_virtual_environment_vm.vm[count.index].ipv6_addresses[1][0]
  }
}
