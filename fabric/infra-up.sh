#!/bin/bash

FABRIC_DIR="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P)"
cd "$FABRIC_DIR"

source fabric-version.env
export FABRIC_IMAGE_TAG

docker-compose-up() {
    docker-compose --project-directory $FABRIC_DIR -p "$1" \
        -f "./configs/docker/$1.docker-compose.yaml" \
        up -d 
}

create-docker-network() {
    if [ ! "$(docker network ls | grep "$1")" ]; then
        docker network create --driver bridge "$1"
    fi
}

./tools-cmd.sh "./clean.sh; ./generate.sh"

create-docker-network "fabric-tools"
create-docker-network "internet"

docker-compose-up "healthblocks"
docker-compose-up "medivale"
docker-compose-up "healpoint"
docker-compose-up "lifecare"