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

log "Stoppin infra..."

function compose_start {
    docker-compose --project-directory "$FABRIC_DIR_PATH" -f "./configs/docker/$1.docker-compose.yaml" -p "$1" start
}

compose_start "medtechchain"
compose_start "medivale"

if [ ! $LIGHT ]; then
    compose_start "healpoint"
    compose_start "lifecare"
fi

cd "./explorer"

if [ $LIGHT ]; then
    EXPLORER_CONFIG_FILE_PATH=./config.light.json
else
    EXPLORER_CONFIG_FILE_PATH=./config.json
fi

export EXPLORER_CONFIG_FILE_PATH

docker-compose start
cd "./.."