#!/bin/bash

if ! docker info > /dev/null 2>&1; then
  echo "Please run docker before running the script"
  exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 && pwd -P)"
cd "$SCRIPT_DIR"

# Changes when the script is moved
FABRIC_DIR="$SCRIPT_DIR"

source "$FABRIC_DIR/scripts/commons.sh"
source "$FABRIC_DIR/.env"

export FABRIC_IMAGE_TAG

#################################################
echo "Stop Explorer..."
pushd "$FABRIC_DIR/explorer"
docker-compose down -v
popd

#################################################
echo "Remove docker containers"

function org_down {
    ORG_NAME="$1"
    docker-compose \
        --project-directory "$FABRIC_DIR" \
        --file "$FABRIC_DIR/configs/docker/orderer.docker-compose.yaml" \
        --file "$FABRIC_DIR/configs/docker/peer.docker-compose.yaml" \
        --project-name "$ORG_NAME" \
        down -v
}

for NAME in ${ORG_NAMES[@]}; do
    org_down "$NAME"
done

#################################################
echo "Remove docker networks"

function rm_docker_network {
    local NETWORK_NAME="$1"

    if [ "$(docker network ls --format "{{.Name}}" | grep "^$NETWORK_NAME$")" ]; then
        docker network rm "$NETWORK_NAME"
    fi
}

for NETWORK in ${DOCKER_NETWORKS[@]}; do
    rm_docker_network "$NETWORK"
done

#################################################
echo "Clean generated files"

GEN_DIR="./.generated"
rm -rf "$GEN_DIR"