#!/bin/bash

FABRIC_DIR="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P)"
cd "$FABRIC_DIR"

CONTAINER_NAME="fabric-tools"

if [ -z "$1" ]; then
    VERSION="latest"
else
    VERSION="$1"
fi

# Connect the container to the network later used
# by the Hyperledger nodes (docker-compose uses this
# external network)
if [ ! "$(docker network ls | grep "healthblocks")" ]; then
    docker network create --driver bridge "healthblocks"
fi

docker run -it \
    --name "$CONTAINER_NAME" \
    --network "healthblocks" \
    -v "$FABRIC_DIR:/home" \
    -w "/home/scripts" \
    "hyperledger/fabric-tools:$VERSION" \
    bash

docker rm "$CONTAINER_NAME" > /dev/null 2>&1