locals {
  docker_vm_count = 1

  tags = [
    "opentofu",
    "komodo",
  ]

  core = {
    hostname = "komodo-01"
  }

  periphery = {
    hostname_prefix = "periphery"
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

resource "proxmox_virtual_environment_download_file" "flatcar" {
  content_type = "iso"       
  datastore_id = var.proxmox_iso_datastore_id
  node_name    = var.proxmox_node
  url          = "https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_proxmoxve_image.img"
  file_name    = "flatcar_production_proxmoxve.img"
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
    komodo_config = templatefile("${path.module}/templates/komodo/core.config.toml.tftpl", {
      github_access_token = var.github_access_token
    })
    # Create a seed configuration to point to the Github repository for the initial sync. 
    # This is necessary to bootstrap the Komodo server with the initial configuration and resources.
    # 
    # See: https://github.com/moghtech/komodo/issues/910#issuecomment-3544626109
    komodo_seed = templatefile("${path.module}/templates/komodo/seed.toml.tftpl", {
      periphery_count = local.periphery.vm_count
    })
  })
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
  description = "Managed by OpenTofu"
  tags        = distinct(concat(local.tags, ["data"]))
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
  description = "Managed by OpenTofu"
  tags        = distinct(concat(local.tags, ["komodo-core"]))

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


data "ct_config" "periphery" {
  count = local.periphery.vm_count

  strict  = true
  content = templatefile("${path.module}/templates/periphery/periphery.bu.tftpl", {
    hostname                  = "${local.periphery.hostname_prefix}${count.index + 1}"
    provision_username        = var.provision_user
    provision_ssh_public_keys = var.provision_ssh_public_keys
    ipv4_cidr                 = "192.168.20.${count.index + 20}/24"
    gateway                   = "192.168.20.1"
    dns                       = "192.168.20.27"
    periphery_compose            = file("${path.module}/templates/periphery/docker-compose.yaml")
    periphery_compose_env        = templatefile("${path.module}/templates/periphery/compose.env.tftpl", {
      hostname              = "${local.periphery.hostname_prefix}${count.index + 1}"
    })
  })
}

resource "proxmox_virtual_environment_file" "periphery_ignition" {
  count = local.periphery.vm_count

  content_type = "snippets"  
  datastore_id = var.proxmox_snippets_datastore_id
  node_name    = var.proxmox_node

  source_raw {
    data      = data.ct_config.periphery[count.index].rendered
    file_name = "${local.periphery.hostname_prefix}${count.index + 1}.ign"
  }
}

# Data VM to hold persistent data for the periphery VM. This is a common pattern in Proxmox to separate data from the OS disk, allowing for easier backups and migrations.
# https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm#example-attached-disks
resource "proxmox_virtual_environment_vm" "periphery_data" {
  count = local.periphery.vm_count

  name      = format("%s-%02d-data", local.periphery.hostname_prefix, count.index + 1)
  description = "Managed by OpenTofu"
  tags        = distinct(concat(local.tags, ["data"]))
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

resource "proxmox_virtual_environment_vm" "periphery" {
  count = local.periphery.vm_count

  name      = format("%s-%02d", local.periphery.hostname_prefix, count.index + 1)
  description = "Managed by OpenTofu"
  tags        = distinct(concat(local.tags, ["komodo-periphery"]))
  node_name = var.proxmox_node
  agent { enabled = false } 

  cpu    { cores = 4 }
  memory { dedicated = 8192 }  

  # Boot disk
  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.flatcar.id
    interface    = "scsi0"
    size         = 16
  }

  # Attach data disk from periphery_data VM
  dynamic "disk" {
    for_each = { for idx, val in proxmox_virtual_environment_vm.periphery_data[count.index].disk : idx => val }
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
    user_data_file_id = proxmox_virtual_environment_file.periphery_ignition[count.index].id
  }
}

output "komodo_sync_instructions" {
  value = <<-EOT
  Everything is set up, but a "seed" resource sync is required to fully implement GitOps. 
  1. Login to the Komodo Core server at https://${local.core.hostname}:9120 
  2. Navigate to the "Syncs" section in the Komodo UI.
  3. Create a new sync with the following configuration and execute it 

  [[resource_sync]]
  name = "seed"
  [resource_sync.config]
  files_on_host = true
  resource_path = ["resources.toml"]
  include_variables = true
  include_user_groups = true
  EOT
}