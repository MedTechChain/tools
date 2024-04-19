#!/usr/bin/env bash

FABRIC_DIR_PATH="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 && pwd -P)"
cd "$FABRIC_DIR_PATH/../../"

COMMAND="$1"

source .env

# Mind that all provided commands should work
# with paths relative to the fabric direcotry 
# (see the bind mount)
docker run --rm -it \
    --name "$CONTAINER_NAME" \
    --network host \
    --volume "./:/home/fabric-dir" \
    --workdir "/home/fabric-dir" \
    "hyperledger/fabric-tools:$FABRIC_IMAGE_TAG" \
    bash -c "$COMMAND"
