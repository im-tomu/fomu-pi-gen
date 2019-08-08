# Fomu pi-gen

Build Status : [![CircleCI](https://circleci.com/gh/im-tomu/fomu-pi-gen.svg?style=svg)](https://circleci.com/gh/im-tomu/fomu-pi-gen)
_Fork of pi-gen used to create the Fomu development image_

For more information, including how to customize this build, see [the original pi-gen repository](https://github.com/RPi-Distro/pi-gen/).

**The default username is `fomu`, and the password is `fomudev`**

The root filesystem is mounted readonly, to prevent card corruption when pulling power.

## Usage

The easiest way to use this repository is via docker.  Run the following
to generate an image:

```sh
sudo modprobe binfmt-misc
./run-build-docker.sh
```

## Configuration

To change the configuration, modify the `config` file in the root.

## Fomu Modifications

This version makes the following changes to the upstream `pi-gen` project:

1. The starting filesystem size is limited to 768 MB, to let users use smaller SD cards.
1. Fewer packages are installed, such as no text editors or GUI
1. A copy of `fomu-flash` is built and installed
1. The root fileystem is mounted readonly, to prevent corruption on unclean shutdown
1. The serial port is enabled, and getty is disabled on ttyS0 and ttyAMA0.
1. Bluetooth is disabled, and Bluetooth software is not installed.

Most changes are done in the `fomu/` directory, however at least some changes were
made to the `export-image/` directory.

## Making Packages


### fomu-flash

```sh
git clone https://github.com/im-tomu/fomu-flash.git
cd fomu-flash
fakeroot
export pkg_version=$(git describe --tags | sed 's/^v//g')
make
mkdir -p fomu-flash_${pkg_version}/usr/bin
cp fomu-flash fomu-flash_${pkg_version}/usr/bin
mkdir fomu-flash_${pkg_version}/DEBIAN
cat > fomu-flash_${pkg_version}/DEBIAN/control <<EOF
Package: fomu-flash
Version: ${pkg_version}
Section: base
Priority: optional
Architecture: armhf
Maintainer: Sean Cross <sean@xobs.io>
Description: Fomu SPI/Bitstream flashing for Raspberry Pi
 Fomu Flash lets you program a bitstream for an ICE40, or
 program the SPI flash attached to the board.
EOF
chmod u+s fomu-flash_${pkg_version}/usr/bin/fomu-flash
dpkg-deb --build fomu-flash_${pkg_version}
exit
```

### yosys

```sh
apt install -y pkg-config libtcl8.6 tclsh build-essential tcl8.6-dev tcl-dev python3 libffi-dev bison flex
git clone https://github.com/YosysHQ/yosys.git
cd yosys
export pkg_version=$(git describe --tags | sed s/yosys-//g)
make config-gcc
make ENABLE_READLINE=0 PREFIX=/usr PREFIX=/usr
make install ENABLE_READLINE=0 PREFIX=/usr DESTDIR=$(pwd)/yosys_${pkg_version}
mkdir yosys_${pkg_version}/DEBIAN
cat > yosys_${pkg_version}/DEBIAN/control <<EOF
Package: yosys
Version: ${pkg_version}
Section: base
Priority: optional
Architecture: armhf
Maintainer: Sean Cross <sean@xobs.io>
Depends: libtcl8.6 (>= 8.6)
Description: Yosys packaged for Fomu
 This is an upstream build of Yosys, specially packaged for Fomu.
EOF
dpkg-deb --build yosys_${pkg_version}
```

### icestorm

```sh
git clone https://github.com/cliffordwolf/icestorm.git
cd icestorm
export pkg_version=0.0.2-$(git rev-parse HEAD)
PREFIX=/usr DESTDIR=$(pwd)/icestorm_${pkg_version} make SUBDIRS="icebox icepack icemulti icepll icetime icebram"
PREFIX=/usr DESTDIR=$(pwd)/icestorm_${pkg_version} make install SUBDIRS="icebox icepack icemulti icepll icetime icebram"
mkdir icestorm_${pkg_version}/DEBIAN
cat > icestorm_${pkg_version}/DEBIAN/control <<EOF
Package: icestorm
Version: ${pkg_version}
Section: base
Priority: optional
Architecture: armhf
Maintainer: Sean Cross <sean@xobs.io>
Description: icestorm packaged for Fomu
 This is an upstream build of icestorm, specially packaged for Fomu.
EOF
dpkg-deb --build icestorm_${pkg_version}
```

### nextpnr

```
apt-get install build-essential libtcl8.6 cmake git make python3-dev libboost-python-dev libboost-filesystem-dev libboost-thread-dev libboost-program-options-dev libboost-iostreams-dev
git clone https://github.com/YosysHQ/nextpnr.git
cd nextpnr
export pkg_version=0.0.3-$(git rev-parse HEAD)
cmake -DARCH=ice40 -DBUILD_GUI=OFF -DICEBOX_ROOT=$(pwd)/../icestorm/icestorm_*/usr/share/icebox -DCMAKE_INSTALL_PREFIX=/usr -DENABLE_READLINE=No .
make
make DESTDIR=$(pwd)/nextpnr-ice40_${pkg_version} install/strip
mkdir nextpnr-ice40_${pkg_version}/DEBIAN
cat > nextpnr-ice40_${pkg_version}/DEBIAN/control <<EOF
Package: nextpnr-ice40
Version: ${pkg_version}
Section: base
Priority: optional
Depends: libboost-regex1.62.0 (>= 1.62.0)
Architecture: armhf
Maintainer: Sean Cross <sean@xobs.io>
Description: nextpnr-ice40 packaged for Fomu
 This is an upstream build of nextpnr, specially packaged for Fomu.
EOF
dpkg-deb --build nextpnr-ice40_${pkg_version}
```

### gcc-riscv

```
apt-get install autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev libeigen3-dev
git clone --recursive https://github.com/riscv/riscv-gnu-toolchain
cd riscv-gnu-toolchains
export pkg_version=8.2.3-$(git rev-parse HEAD)
./configure --prefix=/opt/riscv --enable-multilib --disable-linux
make
mkdir riscv-toolchain_${pkg_version}/
mkdir riscv-toolchain_${pkg_version}/DEBIAN
cat > riscv-toolchain_${pkg_version}/DEBIAN/control <<EOF
Package: riscv-toolchain
Version: ${pkg_version}
Section: base
Priority: optional
Architecture: armhf
Maintainer: Sean Cross <sean@xobs.io>
Description: riscv toolchain packaged for Fomu
 This is an upstream build of riscv, specially packaged for Fomu.
EOF
mkdir riscv-toolchain_${pkg_version}/usr
cp -a /opt/riscv/* riscv-toolchain_${pkg_version}/usr
rm -rf riscv-toolchain_${pkg_version}/usr/include/ riscv-toolchain_${pkg_version}/usr/share/man/man7 riscv-toolchain_${pkg_version}/usr/share/locale riscv-toolchain_${pkg_version}/usr/share/info riscv-toolchain_${pkg_version}/usr/share/gcc-8.2.0/ riscv-toolchain_${pkg_version}/usr/share/gcc-8.3.0/ riscv-toolchain_${pkg_version}/usr/share/gdb
find riscv-toolchain_${pkg_version}/usr/ -name '*.so*' | xargs strip --strip-debug --strip-unneeded
find riscv-toolchain_${pkg_version}/usr/bin | xargs strip --strip-debug --strip-unneeded
find riscv-toolchain_${pkg_version}/usr/riscv64-unknown-elf/bin | xargs strip --strip-debug --strip-unneeded
find riscv-toolchain_${pkg_version}/usr/libexec/gcc/riscv64-unknown-elf/8.3.0/ | xargs strip --strip-debug --strip-unneeded
dpkg-deb --build riscv-toolchain_${pkg_version}
```

### gcc-lm32

```
mkdir lm32-gnu-toolchain
cd lm32-gnu-toolchain
wget https://mirror.freedif.org/GNU/binutils/binutils-2.32.tar.xz
wget https://mirror.freedif.org/GNU/gcc/gcc-8.3.0/gcc-8.3.0.tar.xz
tar xvJf binutils-2.32.tar.xz
tar xvJf gcc-8.3.0.tar.xz
cd binutils-2.32 && mkdir build && cd build
../configure --target=lm32-elf --prefix=/usr && make && DESTDIR=/opt/lm32 make install
cd ../..
cd gcc-8.3.0 && rm -rf libstdc++-v3/ && mkdir build && cd build
export PATH=$PATH:/opt/lm32/usr/bin
../configure --target=lm32-elf --enable-languages="c,c++" --disable-libgcc --disable-libssp --prefix=/usr && make && DESTDIR=/opt/lm32 make install
export pkg_version=8.3.0-fomu
mkdir lm32-toolchain_${pkg_version}/
mkdir lm32-toolchain_${pkg_version}/DEBIAN
cat > lm32-toolchain_${pkg_version}/DEBIAN/control <<EOF
Package: lm32-toolchain
Version: ${pkg_version}
Section: base
Priority: optional
Architecture: armhf
Maintainer: Sean Cross <sean@xobs.io>
Description: lm32 toolchain packaged for Fomu
 This is an upstream build of lm32, specially packaged for Fomu.
EOF
mkdir lm32-toolchain_${pkg_version}/usr
cp -a /opt/lm32/* lm32-toolchain_${pkg_version}/usr
find lm32-toolchain_${pkg_version}/usr | xargs strip --strip-debug --strip-unneeded
dpkg-deb --build lm32-toolchain_${pkg_version}
