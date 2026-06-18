# Proxmox - Homelab 

## Prerequisites

```bash
brew install mise
mise install
```


## Users 

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