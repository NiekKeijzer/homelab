# Proxmox - Homelab 

## Prerequisites

```bash
brew install mise
mise install
```

### Proxmox node boostrap

Run once per fresh Proxmox host, before any IaC touches it. Establishes mrrobot as the admin + automation account. Automated Proxmox installs are out of scope while this stays a home lab.

#### 1. System user (PAM)

Proxmox ships without sudo.

```bash
apt update && apt install -y sudo
adduser mrrobot
usermod -aG sudo mrrobot
```

#### 2. SSH key access

From your workstation:

```bash
ssh-copy-id mrrobot@<host>
```

The rest of the steps can be done either as root or as mrrobot. 

**Always make sure you confirm ssh mrrobot@<host> works before continue.**

#### 3. Proxmox realm & permissions 

Add a PAM user to Proxmox to log into the UI and use the API. 


```bash
sudo pveum user add mrrobot@pam
sudo pveum acl modify / --users mrrobot@pam --roles Administrator
```

#### 4. API token for Packer 

```bash 
sudo pveum user token add mrrobot@pam packer --privsep 0
```

#### 4.1 Register credentials in Fnox 

Persist connection details and credentials in Fnox. You will be prompted for unknown values. Making sure to check the defaults before copy pasting these commands will save you some head scratching later. 

```bash
fnox set PKR_VAR_proxmox_host --provider=age
fnox set PKR_VAR_proxmox_node --provider=age
fnox set PKR_VAR_proxmox_api_token_id --provider=age
fnox set PKR_VAR_proxmox_api_token_secret --provider=age
```

#### 5. API token for OpenTofu 

```bash 
sudo pveum user token add mrrobot@pam opentofu --privsep 0
```

#### 5.1 Register credentials in Fnox 

```bash
fnox set TF_VAR_proxmox_host --provider=age
fnox set TF_VAR_proxmox_node --provider=age
fnox set TF_VAR_proxmox_api_token_id --provider=age
fnox set TF_VAR_proxmox_api_token_secret --provider=age
```

#### 6. Create an ISO and snippet store 

Proxmox already accepts ISOs and snippets in `local` so this step is technically optional. However, this repository assumes both `iso-store` and `snippet-store` exist. 

```bash 
mkdir -p /srv/iso-store /srv/snippet-store
pvesm add dir iso-store --path /srv/iso-store --content iso
pvesm add dir snippet-store --path /srv/snippet-store --content snippets
```



## Repository users 

To add a new user to the repository, ensure an Age key exists. Optionally run on the new machine.

```bash
mise run fnox:age:generate-key
```

On a previously added machine run 
m
```bash
mise run fnox:age:show-public-key
mise run fnox:age:add-public-key <public-key>
```


## Build a Debian 12 Cloud Template for Proxmox

```bash
mise run build-debian-image
```

## Companion repositories 

- [Komodo Periphery Fnox](https://github.com/NiekKeijzer/komodo-periphery-fnox) Komodo Periphery image with Fnox preinstalled