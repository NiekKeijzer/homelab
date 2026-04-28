source "proxmox-iso" "nixos" {

    # Proxmox Settings
    proxmox_url = "https://${var.proxmox_host}:${var.proxmox_port}/api2/json"
    username    = var.proxmox_api_token_id
    token       = var.proxmox_api_token_secret
    insecure_skip_tls_verify = true  # Set to true for self-signed certificates
    node        = var.proxmox_node
    pool = var.proxmox_pool

    # VM General Settings
    vm_id                = "${var.vm_id}"
    vm_name              = "${var.vm_name}"
    template_description = "${title(replace(trimsuffix(var.vm_name, "-template"), "-", " "))} Packer Template -- Created: ${formatdate("YYYY-MM-DD hh:mm:ss ZZZ", timestamp())}"
    tags = join(";", var.vm_tags)
    os                   = "l26"
    machine              = "q35"
    cores                = "2"
    memory               = "2048"
    qemu_agent           = true
    cloud_init = false
    scsi_controller      = "virtio-scsi-pci"

    ssh_username = "nixos"
    ssh_password = "packer"
    ssh_timeout  = "20m"

    boot_iso {
        iso_storage_pool = var.iso_storage_pool
        iso_download_pve = true
        iso_target_path = "${var.vm_name}"
        iso_url          = var.iso_url
        iso_checksum     = var.iso_checksum
        unmount  = true
    }

    disks {
        disk_size = "16G"
        format = "raw"
        storage_pool = "${var.storage_pool}"
        type = "virtio"
    }

    network_adapters {
        bridge = "vmbr0"
        model  = "virtio"
        firewall = false
    }

    http_directory = "${path.root}/http"

    # Boot into the NixOS live environment, then download and run the install
    # script. Packer starts SSH polling immediately after the last entry is sent,
    # relying on the 20 m ssh_timeout to cover the nixos-install + reboot time.
    boot_command = [
        "<enter>",
        "<wait10>",
        "sudo -i<enter>",
        "curl -fsSL http://{{ .HTTPIP }}:{{ .HTTPPort }}/install.sh | bash -s -- http://{{ .HTTPIP }}:{{ .HTTPPort }}<enter>",
    ]

}
