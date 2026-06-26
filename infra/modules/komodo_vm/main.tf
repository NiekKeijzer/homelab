data "ct_config" "this" {
  strict  = true
  content = var.bu_content
}

resource "proxmox_virtual_environment_file" "ignition" {
  content_type = "snippets"
  datastore_id = var.proxmox_snippets_datastore_id
  node_name    = var.proxmox_node

  source_raw {
    data      = data.ct_config.this.rendered
    file_name = "${var.hostname}.ign"
  }
}

# Data VM to hold persistent data for the VM. This is a common pattern in Proxmox to separate data from the OS disk, allowing for easier backups and migrations.
# https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm#example-attached-disks
resource "proxmox_virtual_environment_vm" "data" {
  name        = "${var.vm_name}-data"
  description = "Managed by OpenTofu"
  tags        = distinct(concat(var.base_tags, ["data"]))
  node_name   = var.proxmox_node

  started = false
  on_boot = false

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = var.data_disk_size
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "proxmox_virtual_environment_vm" "this" {
  name        = var.vm_name
  description = "Managed by OpenTofu"
  tags        = distinct(concat(var.base_tags, [var.role_tag]))
  node_name   = var.proxmox_node
  agent { enabled = false }

  cpu    { cores = var.cpu_cores }
  memory { dedicated = var.memory }

  # Boot disk
  disk {
    datastore_id = "local-lvm"
    file_id      = var.flatcar_image_id
    interface    = "scsi0"
    size         = var.boot_disk_size
  }

  # Attach data disk from data VM
  dynamic "disk" {
    for_each = { for idx, val in proxmox_virtual_environment_vm.data.disk : idx => val }
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
    bridge = "vmbr0"
    model  = "virtio"
  }

  initialization {
    datastore_id      = "local-lvm"
    user_data_file_id = proxmox_virtual_environment_file.ignition.id
  }
}
