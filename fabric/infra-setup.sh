#!/bin/bash

FABRIC_DIR="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P)"
cd "$FABRIC_DIR"

if [ -z "$1" ]; then
    VERSION="latest"
else
    VERSION="$1"
fi

export IMAGE_TAG=$VERSION

docker-compose --project-directory $FABRIC_DIR -p healthblocks \
    -f ./configs/docker/healthblocks.com/docker-compose.yaml \
    up -d 