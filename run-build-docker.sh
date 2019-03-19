#!/bin/sh

extra_config="extra-config"

source ./config

IMG_VERSION="$(git describe --tags)"

echo "IMG_VERSION=${IMG_VERSION}" > "${extra_config}"
echo "IMG_FILENAME=${IMG_NAME}-${IMG_VERSION}" >> "${extra_config}"
echo "ZIP_FILENAME=${IMG_NAME}-${IMG_VERSION}" >> "${extra_config}"

./build-docker.sh -c "${extra_config}" 2>&1 | tee build.log
