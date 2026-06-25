terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.93.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "4.0.5"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }

    ansible = {
      source  = "ansible/ansible"
      version = "1.3.0"
    }

    ct = {
      source  = "poseidon/ct"
      version = "0.14.0"
    }
  }
}