#!/bin/bash

if ! docker info >/dev/null 2>&1; then
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
echo "Clean generated files"

GEN_DIR="./.generated"

rm -rf "$GEN_DIR"

#################################################
echo "Create generated files folder structure"

# chaincode packed, shared with all peers
GEN_CC_PKG_DIR="$GEN_DIR/cc-pkg"
mkdir -p "$GEN_CC_PKG_DIR"

# chaincode src, could be shared with only one peer, responsible for building the package
GEN_CC_SRC_DIR="$GEN_DIR/cc-src"
mkdir -p "$GEN_CC_SRC_DIR"

# config tx files and blocks
# each peer subfolder might be shared with multiple peers for signing
GEN_CHANNEL_ARTIFACTS_DIR="$GEN_DIR/artifacts/channel"
for peer_id in ${ORG_PEER_IDS[@]}; do
    mkdir -p "$GEN_CHANNEL_ARTIFACTS_DIR/peer/$peer_id"
done

# crypto material
GEN_CRYPTO_DIR="$GEN_DIR/crypto"
mkdir -p "$GEN_CRYPTO_DIR"

# genesis block of the system channe;, shared with all orderers
GEN_GENESIS_ARTIFACTS_DIR="$GEN_DIR/artifacts/genesis"
mkdir -p "$GEN_GENESIS_ARTIFACTS_DIR"

#################################################
echo "Generate crypto material and artifacts"

./scripts/tools-cmd.sh "cryptogen generate --config=./configs/crypto/crypto-config.yaml --output $GEN_CRYPTO_DIR"

./scripts/tools-cmd.sh "configtxgen \
    -configPath "./configs/configtx" \
    -profile "$GENESIS_PROFILE_NAME" \
    -channelID system-channel \
    -outputBlock "$GEN_GENESIS_ARTIFACTS_DIR/medtechchain-genesis.block""

./scripts/tools-cmd.sh "configtxgen \
    -configPath "./configs/configtx" \
    -profile "$APP_CHANNEL_PROFILE_NAME" \
    -channelID "$CHANNEL_ID" \
    -outputCreateChannelTx "$GEN_CHANNEL_ARTIFACTS_DIR/peer/$INIT_PEER_ID/medtechchain-channel.tx""

#################################################
echo "Set up docker networks"

function create_docker_network {
    local network="$1"

    if [ ! "$(docker network ls --format "{{.Name}}" | grep "^$network$")" ]; then
        docker network create --driver bridge "$network"
    fi
}

for network in ${DOCKER_NETWORKS[@]}; do
    create_docker_network "$network"
done

#################################################
echo "Run organizations infrastructure"

# make sure to export required env vars before call
function container_up {
    kind="$1"
    echo $ORG_NAME
    docker-compose \
        --project-directory "$FABRIC_DIR" \
        --file "$FABRIC_DIR/configs/docker/$kind.docker-compose.yaml" \
        --project-name "$ORG_NAME" \
        up -d
}

function container_down {
    kind="$1"
    docker-compose \
        --project-directory "$FABRIC_DIR" \
        --file "$FABRIC_DIR/configs/docker/$kind.docker-compose.yaml" \
        --project-name "$ORG_NAME" \
        down -v
}

# check for the Docker bug when containers do not join the network / network is not updated
# so the containers cannot communicate
function is_in_network {
    local network="$1"
    local container_to_check="$2"

    if [ "$(docker network inspect "$network" --format '{{range .Containers}}{{.Name}}{{println}}{{end}}' | grep "^$container_to_check$")" ]; then
        return 0
    fi

    return 1
}

function set_orderer_env_vars {
    name="$1"
    i="$2"

    ORG_NAME=$name
    ORG_ORDERER_ID=${ORG_ORDERER_IDS[$name,$i]}
    ORG_ORDERER_LOCALMSPID=${ORG_ORDERER_LOCALMSPIDS[$name]}
    ORG_DOMAIN=${ORG_DOMAINS[$name]}
    ORG_NETWORK=$name

    export ORG_NAME
    export ORG_ORDERER_ID
    export ORG_ORDERER_LOCALMSPID
    export ORG_DOMAIN
    export ORG_NETWORK
}

function set_peer_env_vars {
    name="$1"
    i="$2"

    ORG_NAME=$name
    ORG_PEER_ID=${ORG_PEER_IDS[$name,$i]}
    ORG_ORDERER_ID=${ORG_ORDERER_IDS[$name,0]}
    ORG_PEER_LOCALMSPID=${ORG_PEER_LOCALMSPIDS[$name]}
    ORG_DOMAIN=${ORG_DOMAINS[$name]}
    ORG_NETWORK=$name
    CHAINCODE_HOST_PORT=${CHAINCODE_HOST_PORTS[$ORG_PEER_ID]}

    export ORG_NAME
    export ORG_PEER_ID
    export ORG_ORDERER_ID
    export ORG_PEER_LOCALMSPID
    export ORG_DOMAIN
    export ORG_NETWORK
    export CHAINCODE_HOST_PORT
}

function create_orderer {
    local org_name="$1"
    local orderer_index="$2"

    set_orderer_env_vars $org_name $orderer_index
    container_up orderer

    max_attempts=5
    attempt=1
        
    while ! is_in_network $ORG_NETWORK $ORG_ORDERER_ID || ! is_in_network $GLOBAL_NETWORK $ORG_ORDERER_ID; do
        echo "Warning: Container detected to not join the docker network. Recreating it..."
        container_down orderer
        container_up orderer

        if [ $attempt == $max_attempts ]; then
            echo "Error: Could not set up infra because of containers constantly not joining the docker networks. Abort"
            exit 2
        fi

        ((attempt++))
    done
}

function create_peer {
    local org_name="$1"
    local peer_index="$2"

    set_peer_env_vars $org_name $peer_index
    container_up peer

    max_attempts=5
    attempt=1

    # the latter check is important only for anchor peer
    # so far, all peers are anchor peers
    while ! is_in_network $ORG_NETWORK $ORG_PEER_ID || { [[ " ${ORG_ANCHOR_PEER_IDS[@]} " == *" ${ORG_PEER_ID} "* ]] && ! is_in_network $GLOBAL_NETWORK $ORG_PEER_ID; }; do
        echo "Warning: Container detected to not join the docker network. Recreating it..."
        container_down peer 
        container_up peer

        if [ $attempt == $max_attempts ]; then
            echo "Error: Could not set up infra because of containers constantly not joining the docker networks. Abort"
            exit 2
        fi

        ((attempt++))
    done
}

# Run the containers and check that they join the correct networks
for name in ${ORG_NAMES[@]}; do
    for i in $(seq 0 $((NUM_OF_ORDERERS - 1))); do
        echo "Create orderer for $name, index $i"
        create_orderer $name $i
    done
done

for name in ${ORG_NAMES[@]}; do
    for i in $(seq 0 $((NUM_OF_PEERS - 1))); do
        echo "Create peer for $name, index $i"
        create_peer $name $i
    done
done

#################################################
echo "App channel $CHANNEL_ID is initialised by $INIT_PEER_ID"

docker exec "$INIT_PEER_ID" bash -c "./channel/init-app-channel.sh $INIT_ORG_DOMAIN $INIT_ORDERER_ID $INIT_PEER_ID $CHANNEL_ID"

echo "Peers join $CHANNEL_ID app channel"
for name in ${ORG_NAMES[@]}; do
    ORG_DOMAIN=${ORG_DOMAINS[$name]}
    ORG_ORDERER_ID=${ORG_ORDERER_IDS[$name,0]}
    for i in $(seq 0 $((NUM_OF_PEERS - 1))); do
        ORG_PEER_ID=${ORG_PEER_IDS[$name,$i]}
        
        echo "Peer joins channel, params: $ORG_DOMAIN $ORG_ORDERER_ID $ORG_PEER_ID $CHANNEL_ID"
        docker exec "$ORG_PEER_ID" bash -c "./channel/join-app-channel.sh $ORG_DOMAIN $ORG_ORDERER_ID $ORG_PEER_ID $CHANNEL_ID"
    done
done


#################################################
echo "Start Explorer..."
pushd "$FABRIC_DIR/explorer"
docker-compose up -d
popd

#################################################
echo "Setup Anchor Peers"

for name in ${ORG_NAMES[@]}; do
    ORG_DOMAIN=${ORG_DOMAINS[$name]}
    ORG_ORDERER_ID=${ORG_ORDERER_IDS[$name,0]}
    PEER_GROUP_NAME=${ORG_PEER_GROUP_NAMES[$name]}

    for i in $(seq 0 $((NUM_OF_ANCHOR_PEERS - 1))); do
        ORG_ANCHOR_PEER_ID=${ORG_ANCHOR_PEER_IDS[$name,$i]}

        echo "Anchor peer updates config, params: $ORG_DOMAIN $ORG_ORDERER_ID $ORG_ANCHOR_PEER_ID $CHANNEL_ID"
        docker exec "$ORG_ANCHOR_PEER_ID" bash -c "./channel/fetch-channel-config-block.sh $ORG_DOMAIN $ORG_ORDERER_ID $ORG_ANCHOR_PEER_ID $CHANNEL_ID"
        ./scripts/tools-cmd.sh "./scripts/tools/generate-anchor-peer-update-channel-config.sh $ORG_ANCHOR_PEER_ID $CHANNEL_ID $PEER_GROUP_NAME"
        docker exec "$ORG_ANCHOR_PEER_ID" bash -c "./channel/update-channel-config.sh $ORG_DOMAIN $ORG_ORDERER_ID $ORG_ANCHOR_PEER_ID $CHANNEL_ID"
    done
done

