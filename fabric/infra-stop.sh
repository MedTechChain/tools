#!/usr/bin/env bash

FABRIC_DIR_PATH="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 && pwd -P)"
cd "$FABRIC_DIR_PATH"

source .env
source ../log.sh

export FABRIC_IMAGE_TAG

if [ ! -d "./.generated" ]; then
    error "Generated filed not found. Run ./infra-start.sh first"
    exit 1
fi

if [ -d "./.generated/.light" ]; then
    log "Detected light mode"
    LIGHT="true"
fi

log "Stopping infra..."

cd "./explorer"
docker-compose stop

cd "./.."


function compose_stop {
    docker-compose --project-directory "$FABRIC_DIR_PATH" -f "./configs/docker/$1.docker-compose.yaml" -p "$1" stop
}


PROJECTS=("medtechchain" "medivale")
if [ ! $LIGHT ]; then
    PROJECTS=(${PROJECTS[@]} "healpoint" "lifecare")
fi

for name in ${PROJECTS[@]}; do
    compose_stop "$name"
done

