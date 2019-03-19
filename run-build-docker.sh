#!/bin/sh

extra_config="config"

sed -i '/IMG_VERSION=/d' config
sed -i '/IMG_FILENAME=/d' config
sed -i '/ZIP_FILENAME=/d' config

IMG_VERSION="$(git describe --tags)"

echo "IMG_VERSION=${IMG_VERSION}" >> "${extra_config}"
echo "IMG_FILENAME=${IMG_NAME}-${IMG_VERSION}" >> "${extra_config}"
echo "ZIP_FILENAME=${IMG_NAME}-${IMG_VERSION}" >> "${extra_config}"

./build-docker.sh 2>&1 | tee build.log
git checkout config
