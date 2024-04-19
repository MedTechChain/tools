#!/usr/bin/env bash

FABRIC_DIR_PATH="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 && pwd -P)"
cd "$FABRIC_DIR_PATH"

source .env
source ./scripts/util/log.sh

if [ "$1" == "--light" ]; then
    if [ -d "./.generated" ] && [ ! -d "./.generated/.light" ]; then
        error "There generated files are not generated in light mode. This can cause inconsistenties. Please run ./infra-clean.sh before running light mode"
        exit 1
    fi

    log "Running light mode"
    LIGHT="true"
    mkdir -p "./.generated/.light"
elif [ -n "$1" ]; then
    error "Usage: ./$0 [--light]"
    exit 1
else
    if [ -d "./.generated" ] && [ -d "./.generated/.light" ]; then
        error "There generated files are generated in light mode. This can cause inconsistenties. Please run ./infra-clean.sh before running default mode"
        exit 1
    fi
fi

if ! docker info >/dev/null 2>&1; then
    error "Docker is not running"
    exit 2
fi

export FABRIC_IMAGE_TAG

############### INIT ORG
# When setting up the infrastructure, one organization needs to initilize the app channel
# and deploy the chaincode. These variables are used to automate the process.
INIT_PEER="peer0.medtechchain.nl"
INIT_ORDERER="orderer0.medtechchain.nl"

############### CHANNEL
SYSTEM_CHANNEL="system-channel"
CHANNEL_ID="medtechchain"
GENESIS_PROFILE_NAME="MedTechChainGenesis"
APP_CHANNEL_PROFILE_NAME="MedTechChainChannel"

############### CONFGIS
DOMAINS=("medtechchain.nl" "medivale.nl")
if [ ! $LIGHT ]; then
    DOMAINS=(${DOMAINS[@]} "healpoint.nl" "lifecare.nl")
fi

PROJECTS=("medtechchain" "medivale")
if [ ! $LIGHT ]; then
    PROJECTS=(${PROJECTS[@]} "healpoint" "lifecare")
fi

for domain in ${DOMAINS[@]}; do
    mkdir -p "./.generated/configs/orderer0.$domain"
    cp "./configs/node/orderer.yaml" "./.generated/configs/orderer0.$domain"

    mkdir -p "./.generated/configs/peer0.$domain"
    cp "./configs/node/core.yaml" "./.generated/configs/peer0.$domain"
done

############### CRYPTO MATERIAL
GEN_CRYPTO_PATH="./.generated/crypto"
if [ ! -d $GEN_CRYPTO_PATH ]; then
    log "Generate crypto material"

    if [ $LIGHT ]; then
        CONFIG_CRYPTO_FILE_PATH="./configs/crypto/light/crypto-config.yaml"
    else
        CONFIG_CRYPTO_FILE_PATH="./configs/crypto/crypto-config.yaml"
    fi

    ./scripts/util/tools-cmd.sh "cryptogen generate --config=$CONFIG_CRYPTO_FILE_PATH --output $GEN_CRYPTO_PATH"

else
    log "Crypto material detected. Skipping..."
fi

############### GENESIS BLOCK
GEN_ARTIFACTS_GENESIS_BLOCK_FILE_PATH="./.generated/artifacts/genesis/genesis.block"
if [ ! -f $GEN_ARTIFACTS_GENESIS_BLOCK_FILE_PATH ]; then
    log "Generate genesis block"

    if [ $LIGHT ]; then
        CONFIG_CONFIGTX_PATH="./configs/configtx/light"
    else
        CONFIG_CONFIGTX_PATH="./configs/configtx"
    fi

    ./scripts/util/tools-cmd.sh "configtxgen \
        -configPath $CONFIG_CONFIGTX_PATH \
        -profile $GENESIS_PROFILE_NAME \
        -channelID $SYSTEM_CHANNEL \
        -outputBlock $GEN_ARTIFACTS_GENESIS_BLOCK_FILE_PATH"

else
    log "Genesis block detected. Skipping..."
fi

############### CHANNEL CONFIG TX
CHANNEL_CONFIG_TX_FILE_PATH="./.generated/artifacts/channel/$INIT_PEER/$CHANNEL_ID-channel.tx"
if [ ! -f $CHANNEL_CONFIG_TX_FILE_PATH ]; then
    log "Generate channel config transaction"

    if [ $LIGHT ]; then
        CONFIG_CONFIGTX_PATH="./configs/configtx/light"
    else
        CONFIG_CONFIGTX_PATH="./configs/configtx"
    fi

    ./scripts/util/tools-cmd.sh "configtxgen \
        -configPath $CONFIG_CONFIGTX_PATH \
        -profile $APP_CHANNEL_PROFILE_NAME \
        -channelID $CHANNEL_ID \
        -outputCreateChannelTx $CHANNEL_CONFIG_TX_FILE_PATH"

else
    log "Channel config transaction detected. Skipping..."
fi

############### DOCKER NETWORKS
NETWORKS=("global" "${PROJECTS[@]}")

log "Setup docker networks"
for network in ${NETWORKS[@]}; do
    if [ ! "$(docker network ls --format "{{.Name}}" | grep "^$network$")" ]; then
        docker network create --driver bridge "$network"
        if [ $? -ne 0 ]; then
            error "Could not create network $network. Failed with status $?"
            exit 3
        fi
    fi
done

############### DOCKER COMPOSE
# $1 = project name; $2 = service name
function compose_up {
    docker-compose --project-directory "$FABRIC_DIR_PATH" -f "./configs/docker/$1.docker-compose.yaml" -p "$1" up -d "$2"
}

# $1 = project name; $2 = service name
function compose_down {
    docker-compose --project-directory "$FABRIC_DIR_PATH" -f "./configs/docker/$1.docker-compose.yaml" -p "$1" down -v "$2"
}

# check for the Docker bug when containers do not join the network / network is not updated
# so the containers cannot communicate
# $1 = network name; $2 = container name
function is_in_network {
    if [ "$(docker network inspect "$1" --format '{{range .Containers}}{{.Name}}{{println}}{{end}}' | grep "^$2$")" ]; then
        return 0
    fi
    return 1
}

# $1 = network name; $2 = container name
function is_orderer_connnected {
    if ! is_in_network "$1" "$2" || ! is_in_network "global" "$2"; then
        return 1
    fi
    return 0
}

# $1 = network name; $2 = container name; $3 = "true" if is anchor peer
function is_peer_connected {
    if ! is_in_network "$1" "$2" || { [ "$3" = "true" ] && ! is_in_network "global" "$2"; }; then
        return 1
    fi
    return 0
}

# $1 = orderer | peer; $2 = project name / network; $3 = service name / container id; $4 = "true" if is anchor peer
function create_node {
    local kind="$1"
    local project="$2"
    local network="$2"
    local service="$3"
    local container_id="$3"
    local is_anchor="$4"

    if [ "$kind" != "peer" ] && [ "$kind" != "orderer" ]; then
        error "Invalid argument for create_node"
        exit 4
    fi

    log "Creating $kind: $service"

    local attempt=1
    local max_attempts=5

    compose_up "$project" "$service"

    while { [ "$kind" = "orderer" ] && ! is_orderer_connnected $network $container_id; } || { [ "$kind" = "peer" ] && ! is_peer_connected $network $container_id $is_anchor; }; do
        warn "Container detected to not join the docker network. Recreating it..."

        compose_down "$project" "$service"
        compose_up "$project" "$service"

        if [ $attempt == $max_attempts ]; then
            error "Could not set up infra because of containers constantly not joining the docker networks"
            exit 4
        fi

        ((attempt++))
    done

}

log "Running containers one by one in order to detect the Docker bug when the network DNS is updated when a container joins the network"

for ((i = 0; i < ${#DOMAINS[@]}; i++)); do
    create_node orderer ${PROJECTS[$i]} "orderer0.${DOMAINS[$i]}"
    create_node peer ${PROJECTS[$i]} "peer0.${DOMAINS[$i]}" true
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
done

############### EXPLORER
log "Start explorer"

cd "./explorer"
docker-compose up -d

cd "./.."

############### ANCHOR PEERS
log "Setup anchor peers"

GROUP_NAMES=("MedTechChainPeer" "MediValePeer")
if [ ! $LIGHT ]; then
    GROUP_NAMES=("${GROUP_NAMES[@]}" "HealPointPeer" "LifeCarePeer")
fi

for ((i = 0; i < ${#GROUP_NAMES[@]}; i++)); do
    peer_run "peer0.${DOMAINS[$i]}" "./channel/fetch-channel-config-block.sh orderer0.${DOMAINS[$i]} peer0.${DOMAINS[$i]} $CHANNEL_ID"
    ./scripts/util/tools-cmd.sh "./scripts/tools/generate-anchor-peer-update-channel-config.sh peer0.${DOMAINS[$i]} $CHANNEL_ID ${GROUP_NAMES[$i]}"
    peer_run "peer0.${DOMAINS[$i]}" "./channel/update-channel-config.sh orderer0.${DOMAINS[$i]} peer0.${DOMAINS[$i]} $CHANNEL_ID"
done

log "Restaring Explorer for safety"
docker restart explorer.medtechchain.nl