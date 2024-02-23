#!/bin/bash

FABRIC_FOLDER_PATH="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P)/.."
cd "$FABRIC_FOLDER_PATH"

CONTAINER_NAME="fabric-tools"

docker run -it \
    --name "$CONTAINER_NAME" \
    -v "$FABRIC_FOLDER_PATH:/home/tools" \
    -w "/home/tools" \
    "hyperledger/fabric-tools" \
    bash

docker rm "$CONTAINER_NAME" > /dev/null 2>&1