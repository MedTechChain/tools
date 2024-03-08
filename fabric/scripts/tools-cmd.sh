#!/bin/bash

if [ -z "$2" ] || [ -z "$FABRIC_IMAGE_TAG" ] && [ -z "$1" ]; then
    echo "Usage: ./tools-cmd.sh <CMD> [<FABRIC_IMAGE_TAG>]; if second argument is not specified"
    echo "make sure to have the FABRIC_IMAGE_TAG environment variable set"
    exit 1
fi

CMD="$1"
if [ -z "$FABRIC_IMAGE_TAG" ]; then
    FABRIC_IMAGE_TAG="$2"
fi

SCRIPT_DIR="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 && pwd -P)"
cd "$SCRIPT_DIR"

# Changes when the script is moved
FABRIC_DIR="$SCRIPT_DIR/.."

CONTAINER_NAME="fabric-tools"

docker run -it \
    --name "$CONTAINER_NAME" \
    --network host \
    --volume "$FABRIC_DIR:/home/$USER" \
    --workdir "/home/$USER" \
    "hyperledger/fabric-tools:$FABRIC_IMAGE_TAG" \
    bash -c "$CMD"

docker rm "$CONTAINER_NAME" >/dev/null 2>&1
