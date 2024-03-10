#!/usr/bin/env bash

if ! docker info >/dev/null 2>&1; then
    echo "Error: Docker is not running"
    exit 1
fi

# Many environment variable are read from this script.
# Refer to this file whenever you want to find the value
# or particular variables.
source .env
source ./env.sh
source ./paths.sh

export FABRIC_IMAGE_TAG

############################################################################################################################################
echo -e "\xE2\x9C\x94 >>> STOP EXPLORER <<<"
pushd "$EXPLORER_PATH"
docker-compose down -v
sleep 10
popd

############################################################################################################################################
echo -e "\xE2\x9C\x94 >>> REMOVE DOCKER CONTAINERS <<<"

function org_down {
    local kind="$1"
    local org_name="$2"
    local index="$3"

    if [ "$kind" = "peer" ]; then
        set_peer_env_vars $org_name $index
    elif [ "$kind" = "orderer" ]; then
        set_orderer_env_vars $org_name $index
    else
        echo ">>> ERROR: Invalid argument for org_down"
        exit 3
    fi

    docker-compose --project-directory "$FABRIC_DIR_PATH" -f "$CONFIG_COMPOSE_TEMPLATES_PATH/$kind.docker-compose.yaml" -p "$org_name" down -v --remove-orphans
}

for orderer_key in ${!ORG_ORDERER_ADDRESSES[@]}; do
    org_name="${orderer_key%_*}"
    index="${orderer_key#*_}"

    org_down orderer $org_name $index
done

for peer_key in ${!ORG_PEER_ADDRESSES[@]}; do
    org_name="${peer_key%_*}"
    index="${peer_key#*_}"

    org_down peer $org_name $index
done

############################################################################################################################################
echo -e "\xE2\x9C\x94 >>> REMOVE DOCKER NETWORKS <<<"

function rm_docker_network {
    if [ "$(docker network ls --format "{{.Name}}" | grep "^$$1$")" ]; then
        docker network rm "$1"
    fi
}

for network in ${ALL_NETWORKS[@]}; do
    rm_docker_network "$network"
done

############################################################################################################################################
echo -e "\xE2\x9C\x94 >>> REMOVE CHAINCODE DOCKER IMAGES <<<"
for name in ${ORG_NAMES[@]}; do
    image_ids=$(docker images --format "{{.Repository}}" | grep "$name")
    for id in $image_ids; do
        docker rmi "$id"
    done
done

############################################################################################################################################
echo -e "\xE2\x9C\x94 >>> CLEAN GENERATED FILES <<<"
rm -rf $GEN_PATH
