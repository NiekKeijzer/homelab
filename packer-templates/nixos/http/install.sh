#!/usr/bin/env bash
set -euo pipefail

BASE_URL="$1"

# Partition: MBR, single root partition
parted -s /dev/vda mklabel msdos
parted -s /dev/vda mkpart primary ext4 1MiB 100%
parted -s /dev/vda set 1 boot on

# Format
mkfs.ext4 -L nixos /dev/vda1

# Mount
mount /dev/vda1 /mnt

# Generate hardware-configuration.nix (auto-detects virtio disk, filesystems)
nixos-generate-config --root /mnt

# Replace the generated configuration.nix with our minimal bootable config
curl -fsSL "$BASE_URL/configuration.nix" -o /mnt/etc/nixos/configuration.nix

# Install NixOS non-interactively; nixos user password is set in configuration.nix
nixos-install --no-root-passwd

reboot
