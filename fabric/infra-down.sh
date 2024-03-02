#!/bin/bash

FABRIC_DIR="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P)"
cd "$FABRIC_DIR"

source fabric-version.env
export FABRIC_IMAGE_TAG

docker-compose-down() {
    docker-compose --project-directory $FABRIC_DIR -p "$1" \
        -f "./configs/docker/$1.docker-compose.yaml" \
        down -v
}

delete-docker-network() {
    if [ "$(docker network ls | grep "$1")" ]; then
        docker network rm "$1"
    fi
}

docker-compose-down "lifecare"
docker-compose-down "healpoint"
docker-compose-down "medivale"
docker-compose-down "medtechchain"

delete-docker-network "fabric-tools"
delete-docker-network "internet"


./tools-cmd.sh "./clean.sh"