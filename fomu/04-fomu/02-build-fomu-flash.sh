#!/bin/bash -e

# Build and install fomu-flash
on_chroot << EOF
mkdir -p /usr/src
cd /usr/src
git clone https://github.com/im-tomu/fomu-flash.git
cd fomu-flash
make
install -m 755 fomu-flash /usr/sbin
make clean
EOF
