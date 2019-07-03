#!/bin/bash -e

install -m 644 files/cmdline.txt        "${ROOTFS_DIR}/boot/"
install -m 644 files/config.txt         "${ROOTFS_DIR}/boot/"
install -m 644 files/fstab              "${ROOTFS_DIR}/etc/fstab"

# Disable consoles on the serial port
on_chroot << EOF
systemctl mask serial-getty@ttyAMA0.service
sudo systemctl mask serial-getty@ttyS0.service
EOF
