terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.93.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }

    ansible = {
      source  = "ansible/ansible"
      version = "1.3.0"
    }
  }
}