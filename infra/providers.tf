provider "proxmox" {
  endpoint      = "https://${var.proxmox_host}:${var.proxmox_port}/api2/json"
  api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"
  insecure = true

  ssh {
    username = var.provision_user
    private_key = file("${var.generated_files}/id_ed25519")
  }
}