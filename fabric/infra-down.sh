#!/usr/bin/env bash

FABRIC_DIR_PATH="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 && pwd -P)"
cd "$FABRIC_DIR_PATH"

source .env
source log.sh

export FABRIC_IMAGE_TAG

if [ ! -d "./.generated" ]; then
    error "Generated filed not found. Run ./infra-up.sh first"
    exit 1
fi

if [ -d "./.generated/.light" ]; then
    log "Running light mode"
    LIGHT="true"
fi

############### EXPLORER
log "Stop explorer"
cd "./explorer"

if [ $LIGHT ]; then
    EXPLORER_CONFIG_FILE_PATH=./config.light.json
else
    EXPLORER_CONFIG_FILE_PATH=./config.json
fi

export EXPLORER_CONFIG_FILE_PATH

docker-compose down -v
cd "./.."

############### DOCKER COMPOSE
function compose_down {
    docker-compose --project-directory "$FABRIC_DIR_PATH" -f "./configs/docker/$1.docker-compose.yaml" -p "$1" down -v
}

log "Stopping containers"

compose_down "medtechchain"
compose_down "medivale"

if [ ! $LIGHT ]; then
    compose_down "healpoint"
    compose_down "lifecare"
fi

############### DOCKER COMPOSE
function rm_docker_network {
    if [ "$(docker network ls --format "{{.Name}}" | grep "^$$1$")" ]; then
        docker network rm "$1"
    fi
}

log "Remove docker networks"

rm_docker_network "medtechchain"
rm_docker_network "medivale"

if [ ! $LIGHT ]; then
    rm_docker_network "healpoint"
    rm_docker_network "lifecare"
fi

############### CHAINCODE
log "Remove chaincode docker images"

if [ $LIGHT ]; then
    PROJECTS=("medtechchain" "medivale")
else
    PROJECTS=("medtechchain" "medivale" "healpoint" "lifecare")
fi

for name in ${PROJECTS[@]}; do
    image_ids=$(docker images --format "{{.Repository}}" | grep "$name")
    for id in $image_ids; do
        docker rmi "$id"
    done
done

############### CONFGIS
log "Remove config files"
rm -rf ./.generated
