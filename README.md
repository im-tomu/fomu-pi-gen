# Fomu pi-gen

_Fork of pi-gen used to create the Fomu development image_

For more information, including how to customize this build, see [the original pi-gen repository](https://github.com/RPi-Distro/pi-gen/).

**The default username is `fomu`, and the password is `fomudev`**

The root filesystem is mounted readonly, to prevent card corruption when pulling power.

## Usage

The easiest way to use this repository is via docker.  Run the following
to generate an image:

```sh
sudo modprobe binfmt-support
./build-docker.sh 2>&1 | tee build.log
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
export pkg_version=0.0.1-$(git rev-parse HEAD)
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
apt-get install build-essential libtcl8.6 cmake git make python3-dev libboost-python-dev libboost-filesystem-dev libboost-thread-dev libboost-program-options-dev
git clone https://github.com/YosysHQ/nextpnr.git
cd nextpnr
export pkg_version=0.0.1-$(git rev-parse HEAD)
cmake -DARCH=ice40 -DBUILD_GUI=OFF -DICEBOX_ROOT=$(pwd)/../icestorm/icestorm_*/usr/share/icebox -DCMAKE_INSTALL_PREFIX=/usr -DENABLE_READLINE=No .
make
make DESTDIR=$(pwd)/nextpnr-ice40_${pkg_version} install/strip
mkdir nextpnr-ice40_${pkg_version}/DEBIAN
cat > nextpnr-ice40_${pkg_version}/DEBIAN/control <<EOF
Package: nextpnr-ice40
Version: ${pkg_version}
Section: base
Priority: optional
Architecture: armhf
Maintainer: Sean Cross <sean@xobs.io>
Description: nextpnr-ice40 packaged for Fomu
 This is an upstream build of nextpnr, specially packaged for Fomu.
EOF
dpkg-deb --build nextpnr-ice40_${pkg_version}
```

### gcc-riscv

```
apt-get install autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev
git clone --recursive https://github.com/riscv/riscv-gnu-toolchain
cd riscv-gnu-toolchains
export pkg_version=8.2.0-$(git rev-parse HEAD)
./configure --prefix=/ --enable-multilib
PATH=$PATH:$(pwd)/riscv-gnu-toolchain_${pkg_version}/usr/bin make DESTDIR=$(pwd)/riscv-gnu-toolchain_${pkg_version} -j4

apt-get build-dep gcc
export gcc_version=8.2.0
wget http://ftp.gnu.org/gnu/gcc/gcc-${gcc_version}/gcc-${gcc_version}.tar.gz
tar xvzf gcc-${gcc_version}.tar.gz
cd gcc-${gcc_version}
mkdir build-gcc
cd build-gcc
../gcc/configure \
	--prefix=/ \
	--target=riscv64-unknown-embed-gcc \
	--enable-languages="c" \
	--enable-threads=single \
	--enable-multilib \
	--with-pkgversion=${gcc_version} \
	--without-headers \
	--disable-nls \
	--disable-libatomic \
	--disable-libgcc \
	--disable-libgomp \
	--disable-libmudflap \
	--disable-libquadmath \
	--disable-libssp \
	--disable-nls \
	--disable-shared \
	--disable-tls \
