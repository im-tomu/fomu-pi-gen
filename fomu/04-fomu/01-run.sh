#!/bin/bash -e

install -m 644 files/cmdline.txt        "${ROOTFS_DIR}/boot/"
install -m 644 files/config.txt         "${ROOTFS_DIR}/boot/"
install -m 644 files/fstab              "${ROOTFS_DIR}/etc/fstab"
install -m 644 files/hostname           "${ROOTFS_DIR}/etc/hostname"

# Disable consoles on the serial port
on_chroot << EOF
systemctl mask serial-getty@ttyAMA0.service
sudo systemctl mask serial-getty@ttyS0.service
EOF

# Build and install fomu-flash
on_chroot << EOF
mkdir -p /usr/src
cd /usr/src
git clone https://github.com/im-tomu/fomu-flash.git
cd fomu-flash
make
install -m 755 fomu-flash /usr/sbin
EOF
