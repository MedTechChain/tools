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
# When setting up the infrastructure, one organization needs to initilize the app channel
# and deploy the chaincode. These variables are used to automate the process.
INIT_PEER="peer0.medtechchain.nl"
INIT_ORDERER="orderer0.medtechchain.nl"
CHANNEL_ID="medtechchain"

DOMAINS=("medtechchain.nl" "healpoint.nl" "lifecare.nl")
PROJECTS=("medtechchain" "healpoint" "lifecare")
NETWORKS=("medtechchain-global" "${PROJECTS[@]}")

############### DOCKER NETWORKS
log "Setup docker networks"
for network in ${NETWORKS[@]}; do
    if [ ! "$(docker network ls --format "{{.Name}}" | grep "^$network$")" ]; then
        docker network create --driver bridge "$network"
        if [ $? -ne 0 ]; then
            error "Docker network creation error: $network. Failed with status $?"
            exit 2
        fi
    fi
done

############### DOCKER CONTAINERS
log "Run docker containers"
for project in ${PROJECTS[@]}; do
    docker compose --project-directory "$FABRIC_DIR_PATH" -f "./configs/docker/$project.docker-compose.yaml" -p $project up -d
    if [ $? -ne 0 ]; then
        error "Docker compose up error: $project. Failed with status $?"
        exit 3
    fi
done

log "Wait... (10 seconds)"
sleep 10
############### APP CHANNEL
function peer_run {
    docker exec "$1" bash -c "$2"
}

log "App channel $CHANNEL_ID initialised $INIT_PEER"
peer_run "$INIT_PEER" "./channel/init-app-channel.sh $INIT_ORDERER $INIT_PEER $CHANNEL_ID"

log "Peers join app channel $CHANNEL_ID"
for domain in ${DOMAINS[@]}; do
    peer_run "peer0.$domain" "./channel/join-app-channel.sh $INIT_PEER $CHANNEL_ID"
    sleep 1
done

############### EXPLORER
log "Start explorer"
cd "./explorer"
docker compose up -d
cd "./.."

############### ANCHOR PEERS
log "Setup anchor peers"

GROUP_NAMES=("MedTechChainPeer" "HealPointPeer" "LifeCarePeer")

for ((i = 0; i < ${#GROUP_NAMES[@]}; i++)); do
    peer_run "peer0.${DOMAINS[$i]}" "./channel/fetch-channel-config-block.sh orderer0.${DOMAINS[$i]} peer0.${DOMAINS[$i]} $CHANNEL_ID"
    ./scripts/util/tools-cmd.sh "./scripts/tools/generate-anchor-peer-update-channel-config.sh peer0.${DOMAINS[$i]} $CHANNEL_ID ${GROUP_NAMES[$i]}"
    peer_run "peer0.${DOMAINS[$i]}" "./channel/update-channel-config.sh orderer0.${DOMAINS[$i]} peer0.${DOMAINS[$i]} $CHANNEL_ID"
done

log "Restaring Explorer for safety"
docker restart explorer.medtechchain.nl