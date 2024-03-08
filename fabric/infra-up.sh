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
for DOMAIN in ${ORG_DOMAINS[@]}; do
    mkdir -p "$GEN_CHANNEL_ARTIFACTS_DIR/peer.$DOMAIN"
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

GENESIS_PROFILE_NAME="MedTechChainGenesis"
./scripts/tools-cmd.sh "configtxgen \
    -configPath "./configs/configtx" \
    -profile "$GENESIS_PROFILE_NAME" \
    -channelID system-channel \
    -outputBlock "$GEN_GENESIS_ARTIFACTS_DIR/medtechchain-genesis.block""

./scripts/tools-cmd.sh "configtxgen \
    -configPath "./configs/configtx" \
    -profile "$APP_CHANNEL_PROFILE_NAME" \
    -channelID "$CHANNEL_ID" \
    -outputCreateChannelTx "$GEN_CHANNEL_ARTIFACTS_DIR/peer.medtechchain.nl/medtechchain-channel.tx""

#################################################
echo "Set up docker networks"

function create_docker_network {
    local NETWORK_NAME="$1"

    if [ ! "$(docker network ls --format "{{.Name}}" | grep "^$NETWORK_NAME$")" ]; then
        docker network create --driver bridge "$NETWORK_NAME"
    fi
}

for NETWORK in ${DOCKER_NETWORKS[@]}; do
    create_docker_network "$NETWORK"
done

#################################################
echo "Run organizations infrastructure"

function org_up {
    export ORG_NAME="$1"
    export ORG_DOMAIN="$2"
    export ORG_ORDERER_LOCALMSPID="$3"
    export ORG_PEER_LOCALMSPID="$4"

    docker-compose \
        --project-directory "$FABRIC_DIR" \
        --file "$FABRIC_DIR/configs/docker/base.docker-compose.yaml" \
        --project-name "$ORG_NAME" \
        up --detach
}

for NAME in ${ORG_NAMES[@]}; do
    org_up "$NAME" ${ORG_DOMAINS[$NAME]} ${ORG_ORDERER_LOCALMSPIDS[$NAME]} ${ORG_PEER_LOCALMSPIDS[$NAME]}
done


#################################################
echo "$INIT_PEER creates app channel"



docker exec "peer0.medtechchain.nl" bash -c "./create-app-channel.sh"

for peer in "peer1" "peer2"; do
    docker exec "$peer.medtechchain.nl" bash -c "./join-app-channel.sh $peer medtechchain.nl"
done

echo "Sleep until config block is available to other peers..."
sleep 10

# Other hospitals
for domain in "medivale.nl" "healpoint.nl" "lifecare.nl"; do
    for peer in "peer0" "peer1" "peer2"; do
        docker exec "$peer.$domain" bash -c "./join-app-channel.sh $peer $domain"
    done
done

ORIGINAL_ARGS=("$@")
echo "Set peer2 as anchor peers"
for i in "medtechchain.nl MedTechChainPeer" "medivale.nl MediValePeer" "healpoint.nl HealPointPeer" "lifecare.nl LifeCarePeer"; do
    set -- $i
    docker exec "peer2.$1" bash -c "./fetch-channel-config-block.sh peer2 $1"
    ./tools-cmd.sh "./generate-anchor-peer-update-channel-config.sh peer2 $1 $2"
    docker exec "peer2.$1" bash -c "./update-channel-config.sh peer2 $1"
done
set -- "${ORIGINAL_ARGS[@]}"

echo "Start Explorer..."
pushd "$FABRIC_DIR/explorer"
docker compose up -d
popd

