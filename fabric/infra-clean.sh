#!/usr/bin/env bash

FABRIC_DIR_PATH="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 && pwd -P)"
cd "$FABRIC_DIR_PATH"

source .env
source ./scripts/util/log.sh

export FABRIC_IMAGE_TAG

if [ ! -d "./.generated" ]; then
    error "Generated filed not found. Run ./infra-start.sh first"
    exit 1
fi

if [ -d "./.generated/.light" ]; then
    log "Detected light mode"
    LIGHT="true"
fi

############### EXPLORER
log "Stop explorer"

cd "./explorer"
docker-compose down -v

cd "./.."

############### DOCKER COMPOSE
function compose_down {
    docker-compose --project-directory "$FABRIC_DIR_PATH" -f "./configs/docker/$1.docker-compose.yaml" -p "$1" down -v
}

log "Stopping containers"
PROJECTS=("medtechchain" "medivale")
if [ ! $LIGHT ]; then
    PROJECTS=(${PROJECTS[@]} "healpoint" "lifecare")
fi

for name in ${PROJECTS[@]}; do
    compose_down "$name"
done

############### DOCKER COMPOSE
function rm_docker_network {
    if [ "$(docker network ls --format "{{.Name}}" | grep "^$$1$")" ]; then
        docker network rm "$1"
    fi
}

log "Remove docker networks"
NETWORKS=("global" "medtechchain" "medivale")
if [ ! $LIGHT ]; then
    NETWORKS=(${NETWORKS[@]} "healpoint" "lifecare")
fi

for network in ${NETWORKS[@]}; do
    if [ ! "$(docker network ls --format "{{.Name}}" | grep "^$network$")" ]; then
        docker network rm "$network"
    fi
done

############### CHAINCODE
log "Remove chaincode docker images"

for name in ${PROJECTS[@]}; do
    image_ids=$(docker images --format "{{.Repository}}" | grep "$name")
    for id in $image_ids; do
        docker rmi "$id"
    done
done

############### CONFGIS
log "Remove config files"
rm -rf ./.generated
