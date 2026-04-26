output "vm_names" {
  description = "Names of the created VMs."
  value       = proxmox_virtual_environment_vm.vm[*].name
}

output "vm_ids" {
  description = "Proxmox VM IDs of the created VMs."
  value       = proxmox_virtual_environment_vm.vm[*].vm_id
}

output "ipv4_addresses" {
  description = "Primary IPv4 addresses of the created VMs."
  value       = [for vm in proxmox_virtual_environment_vm.vm : vm.ipv4_addresses[1][0]]
}

output "ipv6_addresses" {
  description = "Primary IPv6 addresses of the created VMs."
  value       = [for vm in proxmox_virtual_environment_vm.vm : vm.ipv6_addresses[1][0]]
}

output "ansible_host_names" {
  description = "Ansible inventory host names for the created VMs."
  value       = ansible_host.vm[*].name
}
