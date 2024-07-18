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

log "Stopping infra..."

cd "./explorer"
docker compose stop
cd "./.."

for project in ${PROJECTS[@]}; do
    docker compose --project-directory "$FABRIC_DIR_PATH" -f "./configs/docker/$project.docker-compose.yaml" -p "$project" stop
done

