#!/bin/bash

FABRIC_DIR="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P)"
cd "$FABRIC_DIR"

if [ -z "$1" ]; then
    echo "Usage: ./tools-cmd.sh <CMD>"
fi

source fabric-version.env

CONTAINER_NAME="fabric-tools-cmd"
NETWORK_NAME="fabric-tools"


# Connect the container to the network later used
# by the Hyperledger nodes (docker-compose uses this
# external network)
if [ ! "$(docker network ls | grep "$NETWORK_NAME")" ]; then
    docker network create --driver bridge "$NETWORK_NAME"
fi

docker run \
    --name "$CONTAINER_NAME" \
    --network "$NETWORK_NAME" \
    -v "$FABRIC_DIR:/home" \
    -w "/home/scripts" \
    "hyperledger/fabric-tools:$FABRIC_IMAGE_TAG" \
    bash -c "$1"

docker rm "$CONTAINER_NAME" > /dev/null 2>&1