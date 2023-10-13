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
GENTOO_HOSTNAME="myLocalhost"
GENTOO_MIRRORS="https://ftp.belnet.be/pub/rsync.gentoo.org/gentoo/ rsync://ftp.belnet.be/gentoo/gentoo/"
GENTOO_PROFILE=`eselect profile list| grep -E "/desktop/systemd "| cut -f2 -d\[| grep -oE "^[0-9]+"`
GENTOO_LOCALE=`locale-gen && eselect locale list| grep "en_US.utf8"| cut -f2 -d\[| grep -oE "^[0-9]+"`
STAGING_URL="https://distfiles.gentoo.org/releases/amd64/autobuilds/20231008T170201Z/stage3-amd64-desktop-systemd-20231008T170201Z.tar.xz"

function config_env {
  chroot /mnt/gentoo /bin/bash
  source /etc/profile
  export PS1="(chroot) ${PS1}"
}

function config_locale {
  eselect locale set ${GENTOO_LOCALE}
  env-update && source /etc/profile && export PS1="(chroot) ${PS1}"
}

function config_mirrors {
  echo ${GENTOO_MIRRORS} >> /mnt/gentoo/etc/portage/make.conf
  mkdir --parents /mnt/gentoo/etc/portage/repos.conf
  cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf
  cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
}

function config_portage {
  emerge-webrsync
  emerge --sync
  eselect profile set ${GENTOO_PROFILE}
  emerge --update --deep --newuse @world
  echo 'ACCEPT_LICENSE="-* @FREE @BINARY-REDISTRIBUTABLE"' >> /etc/portage/make.conf
}

function install_kernel {
  emerge sys-kernel/linux-firmware
  emerge sys-kernel/installkernel-gentoo
  emerge sys-kernel/gentoo-sources

  cd /usr/src/linux
  make x86_64_defconfig
  make && make modules_install
  make install
}

function install_staging {
  cd /mnt/gentoo
  wget ${STAGING_URL}
  tar xvpf stag3-*.tar.xz --xattrs-include='*.*' --numeric-owner
}

function mk_disk {
  parted -s ${HDD_DEVICE} -- \
  mklabel gpt \
  mkpart primary ext2 ${HDD_DEVICE_START} ${HDD_BOOT_SIZE} \
  mkpart primary linux-swap ${HDD_BOOT_SIZE} ${HDD_SWAP_SIZE} \
  mkpart primary ext4 ${HDD_SWAP_SIZE} ${HDD_ROOT_SIZE}

  mkfs.ext2 /dev/sda1
  mkswap /dev/sda2
  mkfs.ext4 /dev/sda3
}

function mount_disk {
  mount /dev/sda1 /boot
  swapon /dev/sda2
  mount /dev/sda3 /mnt/gentoo

  chmod 1777 /mnt/gentoo/tmp

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
  # install_staging
  # config_mirrors
  mount_disk
  # config_env
  # config_portage
  # config_locale
  # install_kernel
}

main
