locals {
  docker_vm_count = 1
  vm_template = local.vm_templates["debian-13"]

  core = {
    hostname = "komodo-01"
  }

  periphery = {
    hostname_prefix = "periphery-"
    vm_count       = 1
  }
}

resource "random_password" "komodo_db_password" {
  length  = 32
  special = false
}

resource "random_password" "komodo_admin_password" {
  length  = 32
  special = false
}

resource "random_password" "komodo_webhook_secret" {
  length  = 32
  special = false
}

resource "random_password" "komodo_jwt_secret" {
  length  = 32
  special = false
}

data "ct_config" "core" {
  strict  = true
  content = templatefile("${path.module}/templates/komodo/core.bu.tftpl", {
    hostname                  = local.core.hostname
    provision_username        = var.provision_user
    provision_ssh_public_keys = var.provision_ssh_public_keys
    ipv4_cidr                 = "192.168.20.10/24"
    gateway                   = "192.168.20.1"
    dns                       = "192.168.20.27"
    komodo_compose            = file("${path.module}/templates/komodo/docker-compose.yaml")
    komodo_compose_env        = templatefile("${path.module}/templates/komodo/compose.env.tftpl", {
      hostname              = local.core.hostname
      komodo_db_password    = random_password.komodo_db_password.result
      komodo_webhook_secret = random_password.komodo_webhook_secret.result
      komodo_jwt_secret     = random_password.komodo_jwt_secret.result
    })
  })
}


resource "proxmox_virtual_environment_download_file" "flatcar" {
  content_type = "iso"       
  datastore_id = var.proxmox_iso_datastore_id
  node_name    = var.proxmox_node
  url          = "https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_proxmoxve_image.img"
  file_name    = "flatcar_production_proxmoxve.img"
}

resource "proxmox_virtual_environment_file" "ignition" {
  content_type = "snippets"  
  datastore_id = var.proxmox_snippets_datastore_id
  node_name    = var.proxmox_node

  source_raw {
    data      = data.ct_config.core.rendered
    file_name = "${local.core.hostname}.ign"
  }
}

# Data VM to hold persistent data for the core VM. This is a common pattern in Proxmox to separate data from the OS disk, allowing for easier backups and migrations.
# https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm#example-attached-disks
resource "proxmox_virtual_environment_vm" "core_data" {
  name      = "${local.core.hostname}-data"
  node_name = var.proxmox_node

  started = false
  on_boot = false

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 32
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "proxmox_virtual_environment_vm" "core" {
  name      = local.core.hostname
  node_name = var.proxmox_node
  agent { enabled = false } 

  cpu    { cores = 2 }
  memory { dedicated = 2048 }  

  # Boot disk
  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.flatcar.id
    interface    = "scsi0"
    size         = 16
  }

  # Attach data disk from core_data VM
  dynamic "disk" {
    for_each = { for idx, val in proxmox_virtual_environment_vm.core_data.disk : idx => val }
    iterator = data_disk

    content {
      datastore_id      = data_disk.value["datastore_id"]
      path_in_datastore = data_disk.value["path_in_datastore"]
      file_format       = data_disk.value["file_format"]
      size              = data_disk.value["size"]
      # assign from scsi1 and up
      interface         = "scsi${data_disk.key + 1}"
    }
  }

  network_device {
    bridge  = "vmbr0"
    model   = "virtio"
  }

  initialization {
    datastore_id      = "local-lvm"
    user_data_file_id = proxmox_virtual_environment_file.ignition.id
  }
}