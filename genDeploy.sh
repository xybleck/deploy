#!/bin/bash
#
#
#
#
#
HDD_DEVICE="/dev/sda"
HDD_DEVICE_START=0
HDD_BOOT_SIZE="2000MiB"
HDD_SWAP_SIZE="4000MiB"
HDD_ROOT_SIZE="-1s"
STAGING_URL="https://distfiles.gentoo.org/releases/amd64/autobuilds/20231008T170201Z/stage3-amd64-desktop-systemd-20231008T170201Z.tar.xz"

function mk_disk {
  parted -s ${HDD_DEVICE} -- \
  mklabel gpt \
  mkpart primary ext2 ${HDD_DEVICE_START} ${HDD_BOOT_SIZE} \
  mkpart primary linux-swap ${HDD_BOOT_SIZE} ${HDD_SWAP_SIZE} \
  mkpart primary ext4 ${HDD_SWAP_SIZE} ${HDD_ROOT_SIZE}

  mkfs.ext2 /dev/sda1
  swapon /dev/sda2
  mkfs.ext4 /dev/sda3
}

function mount_disk {
  mount /dev/sda1 /boot
  swapon /dev/sda2
  mount /dev/sda3 /mnt/gentoo

  mount --types proc /proc /mnt/gentoo/proc
  mount --rbind /sys /mnt/gentoo/sys
  mount --make-rslave /mnt/gentoo/sys
  mount --rbind /dev /mnt/gentoo/dev
  mount --make-rslave /mnt/gentoo/dev
  mount --rbind /run /mnt/gentoo/run
  mount --make-rslave /mnt/gentoo/run
}

function main {
  mk_disk
  mount_disk
}

main
