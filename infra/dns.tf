locals {
  dns_node_count = 1
}

resource "local_file" "dns_user_data" {
  count = local.dns_node_count

  content = templatefile("${path.module}/templates/dns-user-data.yaml.tftpl", {
    hostname = format("dns-%02s", count.index + 1),
    provision_user = var.provision_user,
    provision_ssh_public_keys = var.provision_ssh_public_keys,
  })
  filename = "${var.generated_files}/${format("dns-%02s", count.index + 1)}-user-data.yaml"
}

resource "ansible_host" "dns" {
  depends_on = [local_file.dns_user_data]

  count = local.dns_node_count

  groups = ["dns", ]

  name = format("dns-%02s", count.index + 1)
  variables = {
    # TODO: DHCP reservations in Unifi
    # TODO: Local DNS entry in Unifi for the node(s) to avoid having to use the IP address(es) in the Ansible inventory
    ansible_host                 = format("dns-%02s.%s", count.index + 1, var.node_domain)
  }
}

output "dns_user_data_instructions" {
  value = <<-EOT
  The user-data file(s) for the RPI DNS node(s) have been generated in the ${var.generated_files} directory. 
  You can use these files to provision the DNS node(s) by copying the respective file(s) to the root of the SD card(s) used for the RPI DNS node(s).
  The file(s) are named according to the format "dns-XX.node_domain-user-data.yaml", where XX is the node number and node_domain is the domain specified in the variables.
  EOT
}