locals {
  tags = [
    "opentofu",
    "komodo",
  ]

  # One flat L2 network (VLAN 20). Every VM's interface is a /24 on this
  # subnet; the per-role "blocks" below are just reserved host-number ranges
  # within it, NOT separate networks. The interface mask always comes from
  # network.cidr so the gateway and every other node stay directly reachable.

  # Komodo stack: 192.168.20.16/28 (.16–.31, 16 reserved IPs)
  #   Core:      192.168.20.16/30 (.16–.19, 4 slots)
  #   Spare:                      (.20–.23, 4 unassigned)
  #   Periphery: 192.168.20.24/29 (.24–.31, 8 slots)
  network = {
    cidr    = var.cidr
    gateway = var.gateway
    dns = var.dns
  }

  network_prefix = tonumber(split("/", local.network.cidr)[1])

  core = {
    hostname = "komodo-01"
    network = {
      # /30 block at .16–.19: newbits=6 (30-24), netnum=4 (16/4)
      cidr = cidrsubnet(local.network.cidr, 6, 4)
    }
  }

  periphery = {
    hostname_prefix = "periphery"
    vm_count        = 1
    network = {
      # /29 block at .24–.31: newbits=5 (29-24), netnum=3 (24/8)
      cidr = cidrsubnet(local.network.cidr, 5, 3)
    }
  }
}

resource "random_password" "komodo_db_password" {
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

module "core" {
  source = "./modules/komodo_vm"

  hostname = local.core.hostname
  vm_name  = local.core.hostname

  bu_content = templatefile("${path.module}/templates/komodo/core.bu.tftpl", {
    hostname                  = local.core.hostname
    provision_username        = var.provision_user
    provision_ssh_public_keys = var.provision_ssh_public_keys
    ipv4_cidr                 = "${cidrhost(local.core.network.cidr, 0)}/${local.network_prefix}"
    gateway                   = local.network.gateway
    dns                       = local.network.dns
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
      periphery_servers = [for i in range(local.periphery.vm_count) : {
        name = format("periphery-%02d", i + 1)
        ip   = cidrhost(local.periphery.network.cidr, i)
      }]
    })
  })

  base_tags = local.tags
  role_tag  = "komodo-core"
  cpu_cores = 2
  memory    = 2048

  flatcar_image_id              = proxmox_virtual_environment_download_file.flatcar.id
  proxmox_node                  = var.proxmox_node
  proxmox_snippets_datastore_id = var.proxmox_snippets_datastore_id
}

module "periphery" {
  count  = local.periphery.vm_count
  source = "./modules/komodo_vm"

  hostname = format("%s-%02d", local.periphery.hostname_prefix, count.index + 1)
  vm_name  = format("%s-%02d", local.periphery.hostname_prefix, count.index + 1)

  bu_content = templatefile("${path.module}/templates/periphery/periphery.bu.tftpl", {
    hostname                  = format("%s-%02d", local.periphery.hostname_prefix, count.index + 1)
    provision_username        = var.provision_user
    provision_ssh_public_keys = var.provision_ssh_public_keys
    ipv4_cidr                 = "${cidrhost(local.periphery.network.cidr, count.index)}/${local.network_prefix}"
    gateway                   = local.network.gateway
    dns                       = local.network.dns
    periphery_compose         = file("${path.module}/templates/periphery/docker-compose.yaml")
    periphery_compose_env     = templatefile("${path.module}/templates/periphery/compose.env.tftpl", {
      hostname = format("%s-%02d", local.periphery.hostname_prefix, count.index + 1)
    })
  })

  base_tags = local.tags
  role_tag  = "komodo-periphery"
  cpu_cores = 4
  memory    = 8192

  flatcar_image_id              = proxmox_virtual_environment_download_file.flatcar.id
  proxmox_node                  = var.proxmox_node
  proxmox_snippets_datastore_id = var.proxmox_snippets_datastore_id
}

output "komodo_sync_instructions" {
  value = <<-EOT
  If this was the first time you deployed the Komodo stack, you will need to perform a "seed" resource sync to fully implement GitOps. Follow these steps:

  1. Login to the Komodo Core server at https://${cidrhost(local.core.network.cidr, 0)}:9120 
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
