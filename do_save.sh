#!/usr/bin/env bash
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DOCKER_IMAGE_TAG="rare26-algorithm"

echo "=+= (Re)build the container"
source "${SCRIPT_DIR}/do_build.sh"

build_timestamp=$(docker inspect --format='{{ .Created }}' "$DOCKER_IMAGE_TAG")
formatted=$(echo $build_timestamp | sed -E 's/(.*)T(.*)\..*Z/\1_\2/' | sed 's/[-,:]/-/g')
output_filename="${SCRIPT_DIR}/${DOCKER_IMAGE_TAG}_${formatted}.tar.gz"

echo "==+=="
echo "Saving image → ${output_filename}"
docker save "$DOCKER_IMAGE_TAG" | gzip -c > "$output_filename"
echo "Saved: ${output_filename}"
echo "==+=="
echo "Upload this file to Grand Challenge → Submit → Containers → Upload a Container"