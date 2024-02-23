#!/bin/bash

SCRIPT_PATH="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P)"
FABRIC_FOLDER_PATH="$SCRIPT_PATH/.."
GENERATED_FILES_PATH="$FABRIC_FOLDER_PATH/.generated"

CONTAINER_NAME="cryptogen-generate"

CRYPTOGEN_CONFIG="$SCRIPT_PATH/crypto-config.yaml"
CRYPTOGEN_GENERATED_FILES_PATH="$GENERATED_FILES_PATH/cryptogen"

cd "$SCRIPT_PATH"

docker run -it \
    --name "$CONTAINER_NAME" \
    -v "$CRYPTOGEN_GENERATED_FILES_PATH:/home/cryptogen/generated" \
    -v "$CRYPTOGEN_CONFIG:/home/cryptogen/crypto-config.yaml" \
    -w "/home/cryptogen" \
    "hyperledger/fabric-tools" \
    bash -c "$1"

docker rm "$CONTAINER_NAME" > /dev/null 2>&1