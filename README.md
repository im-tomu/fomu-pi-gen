# Fomu pi-gen

_Fork of pi-gen used to create the Fomu development image_

For more information, including how to customize this build, see [the original pi-gen repository](https://github.com/RPi-Distro/pi-gen/).

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
