#!/usr/bin/env bash
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DOCKER_IMAGE_TAG="rare26-algorithm"
DOCKER_NOOP_VOLUME="${DOCKER_IMAGE_TAG}-volume"

INPUT_DIR="${SCRIPT_DIR}/test/input"
OUTPUT_DIR="${SCRIPT_DIR}/test/output"

echo "=+= (Re)build the container"
source "${SCRIPT_DIR}/do_build.sh"

cleanup() {
    echo "=+= Cleaning permissions..."
    docker run --rm \
      --platform=linux/amd64 \
      --quiet \
      --volume "$OUTPUT_DIR":/output \
      --entrypoint /bin/sh \
      $DOCKER_IMAGE_TAG \
      -c "chmod -R -f o+rwX /output/* || true"
    docker volume rm "$DOCKER_NOOP_VOLUME" > /dev/null 2>&1 || true
}

chmod -R -f o+rX "$INPUT_DIR"

if [ -d "${OUTPUT_DIR}/interface_0" ]; then
    chmod -f o+rwX "${OUTPUT_DIR}/interface_0"
    echo "=+= Cleaning up earlier output"
    docker run --rm \
        --platform=linux/amd64 \
        --quiet \
        --volume "${OUTPUT_DIR}/interface_0":/output \
        --entrypoint /bin/sh \
        $DOCKER_IMAGE_TAG \
        -c "rm -rf /output/* || true"
else
    mkdir -p -m o+rwX "${OUTPUT_DIR}/interface_0"
fi

docker volume create "$DOCKER_NOOP_VOLUME" > /dev/null
trap cleanup EXIT

echo "=+= Running forward pass on interface_0..."
docker run --rm \
    --platform=linux/amd64 \
    --network none \
    --gpus all \
    --volume "${INPUT_DIR}/interface_0":/input:ro \
    --volume "${OUTPUT_DIR}/interface_0":/output \
    --volume "$DOCKER_NOOP_VOLUME":/tmp \
    "$DOCKER_IMAGE_TAG"

echo ""
echo "=+= Output:"
cat "${OUTPUT_DIR}/interface_0/stacked-neoplastic-lesion-likelihoods.json" 2>/dev/null \
    || echo "WARNING: output file not found"

echo ""
echo "=+= Save this image for uploading via ./do_save.sh"