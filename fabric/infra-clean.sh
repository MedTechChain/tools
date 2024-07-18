#!/usr/bin/env bash

FABRIC_DIR_PATH="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 && pwd -P)"
cd "$FABRIC_DIR_PATH"

source .env
source ./scripts/util/log.sh

if ! docker info >/dev/null 2>&1; then
    error "Docker is not running"
    exit 1
fi

export FABRIC_IMAGE_TAG

############### VARIABLES
PROJECTS=("medtechchain" "healpoint" "lifecare")
NETWORKS=("medtechchain-global" "${PROJECTS[@]}")

############### EXPLORER
log "Stop explorer"
cd "./explorer"
docker compose down -v
cd "./.."

############### DOCKER CONTAINERS
log "Stopping containers"
for project in ${PROJECTS[@]}; do
    docker compose --project-directory "$FABRIC_DIR_PATH" -f "./configs/docker/$project.docker-compose.yaml" -p "$project" down -v
done

############### DOCKER NETWORKS
log "Remove docker networks"
for network in ${NETWORKS[@]}; do
    if [ ! "$(docker network ls --format "{{.Name}}" | grep "^$network$")" ]; then
        docker network rm "$network"
    fi
done

############### CHAINCODE
log "Remove chaincode docker images"
for name in ${PROJECTS[@]}; do
    image_ids=$(docker images --format "{{.Repository}}" | grep "$name-")
    for id in $image_ids; do
        docker rmi "$id"
    done
done

############### GENERATED
rm -rf ./.generated
