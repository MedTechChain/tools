#!/usr/bin/env bash

cd -- "$(dirname "$0")"

COMMAND="$1"

source ./.env
source ./paths.sh

CONTAINER_NAME="fabric-tools"

# Mind that all provided commands should work
# with paths relative to the fabric direcotry 
# (see the bind mount)
docker run -it \
    --name "$CONTAINER_NAME" \
    --network host \
    --volume "$FABRIC_DIR_PATH:/home/$USER" \
    --workdir "/home/$USER" \
    "hyperledger/fabric-tools:$FABRIC_IMAGE_TAG" \
    bash -c "$COMMAND"

docker rm -v "$CONTAINER_NAME" >/dev/null 2>&1
