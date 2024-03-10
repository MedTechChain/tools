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
echo -e "\xE2\x9C\x94 >>> GENERATE CRYPTO MATERIAL <<<"
./tools-cmd.sh "cryptogen generate --config=$CONFIG_CRYPTO_FILE_PATH --output $GEN_CRYPTO_PATH"

echo -e "\xE2\x9C\x94 >>> GENERATE GENESIS BLOCK <<<"
./tools-cmd.sh "configtxgen \
    -configPath "$CONFIG_CONFIGTX_PATH" \
    -profile "$GENESIS_PROFILE_NAME" \
    -channelID $SYSTEM_CHANNEL \
    -outputBlock "$GEN_ARTIFACTS_GENESIS_BLOCK_FILE_PATH""

echo -e "\xE2\x9C\x94 >>> GENERATE CHANNEL ARTIFACTS <<<"
./tools-cmd.sh "configtxgen \
    -configPath "$CONFIG_CONFIGTX_PATH" \
    -profile "$APP_CHANNEL_PROFILE_NAME" \
    -channelID "$CHANNEL_ID" \
    -outputCreateChannelTx "$GEN_ARTIFACTS_CHANNEL_PATH/$INIT_PEER_ADDRESS/$CHANNEL_ID-channel.tx""

############################################################################################################################################
echo -e "\xE2\x9C\x94 >>> SETUP DOCKER NETWORKS <<<"

for network in ${ALL_NETWORKS[@]}; do
    if [ ! "$(docker network ls --format "{{.Name}}" | grep "^$network$")" ]; then
        docker network create --driver bridge "$network"
    fi
done

############################################################################################################################################
echo -e "\xE2\x9C\x94 >>> SETUP DOCKER CONTAINERS (IGNORE THE WARNINGS) <<<"

# make sure to export required env vars before call
# $1 = orderer | peer
function container_up {
    docker-compose --project-directory "$FABRIC_DIR_PATH" -f "$CONFIG_COMPOSE_TEMPLATES_PATH/$1.docker-compose.yaml" -p "$ORG_NAME" up -d
}

# $1 = orderer | peer
function container_down {
    docker-compose --project-directory "$FABRIC_DIR_PATH" -f "$CONFIG_COMPOSE_TEMPLATES_PATH/$1.docker-compose.yaml" -p "$ORG_NAME" down -v
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

function is_orderer_connnected {
    is_in_network "$ORG_NETWORK" "$ORDERER_ADDRESS"
    if ! is_in_network "$ORG_NETWORK" "$ORDERER_ADDRESS" || ! is_in_network "$GLOBAL_NETWORK" "$ORDERER_ADDRESS"; then
        return 1
    fi
    return 0
}

function is_peer_connected {
    if ! is_in_network "$ORG_NETWORK" "$PEER_ADDRESS" || { [[ " ${ORG_ANCHOR_PEER_ADDRESSES[@]} " == *" $PEER_ADDRESS "* ]] && ! is_in_network "$GLOBAL_NETWORK" "$PEER_ADDRESS"; }; then
        return 1
    fi
    return 0
}

# $1 = orderer | peer; $2 = org. name; $3 = index
function create_node {
    local kind="$1"
    local org_name="$2"
    local index="$3"

    local max_attempts=5
    local attempt=1

    if [ "$kind" = "peer" ]; then
        set_peer_env_vars $org_name $index
    elif [ "$kind" = "orderer" ]; then
        set_orderer_env_vars $org_name $index
    else
        echo ">>> ERROR: Invalid argument for create_node <<<"
        exit 2
    fi

    container_up "$kind"

    while { [ "$kind" = "orderer" ] && ! is_orderer_connnected; } || { [ "$kind" = "peer" ] && ! is_peer_connected; }; do
        echo ">>> WARNING: Container detected to not join the docker network. Recreating it... <<<"
        container_down "$kind"
        container_up "$kind"

        if [ $attempt == $max_attempts ]; then
            echo ">>> ERROR: Could not set up infra because of containers constantly not joining the docker networks. <<<"
            exit 3
        fi

        ((attempt++))
    done

}

# Run the containers and check that they join the correct networks
for orderer_key in ${!ORG_ORDERER_ADDRESSES[@]}; do
    org_name="${orderer_key%_*}"
    index="${orderer_key#*_}"

    echo ">>> CREATE ORDERER: $org_name, $index"
    create_node orderer $org_name $index
done

for peer_key in ${!ORG_PEER_ADDRESSES[@]}; do
    org_name="${peer_key%_*}"
    index="${peer_key#*_}"

    echo ">>> CREATE PEER: $org_name, $index"
    create_node peer $org_name $index
done


############################################################################################################################################
echo -e "\xE2\x9C\x94 >>> APP CHANNEL $CHANNEL_ID IS INITILAISED BY $INIT_PEER_ADDRESS <<<"
docker exec "$INIT_PEER_ADDRESS" bash -c "./channel/init-app-channel.sh $INIT_ORDERER_ADDRESS $INIT_PEER_ADDRESS $CHANNEL_ID"

echo -e "\xE2\x9C\x94 >>> PEERS JOIN $CHANNEL_ID APP CHANNEL <<<"
for peer_address in ${ORG_PEER_ADDRESSES[@]}; do
    echo ">>> PEER JOINS APP CHANNEL: $peer_address"
    docker exec "$peer_address" bash -c "./channel/join-app-channel.sh $INIT_PEER_ADDRESS $CHANNEL_ID"
done

############################################################################################################################################
echo -e "\xE2\x9C\x94 >>> START EXPLORER <<<"
pushd "$EXPLORER_PATH"
docker-compose up -d
popd

############################################################################################################################################
echo -e "\xE2\x9C\x94 >>> SETUP ANCHOR PEERS <<<"

for anchor_peer_key in ${!ORG_ANCHOR_PEER_ADDRESSES[@]}; do
    org_name="${anchor_peer_key%_*}"

    orderer_key="${org_name}_0"
    ORG_ORDERER_ADDRESS=${ORG_ORDERER_ADDRESSES[$orderer_key]}
    PEER_GROUP_NAME=${PEER_GROUP_NAMES[$org_name]}
    ORG_ANCHOR_PEER_ADDRESS=${ORG_ANCHOR_PEER_ADDRESSES[$anchor_peer_key]}

    echo ">>> $ORG_ANCHOR_PEER_ADDRESS ANCHOR PEER MODIFIES APP CHANNEL CONFIG"

    docker exec "$ORG_ANCHOR_PEER_ADDRESS" bash -c "./channel/fetch-channel-config-block.sh $ORG_ORDERER_ADDRESS $ORG_ANCHOR_PEER_ADDRESS $CHANNEL_ID"
    ./tools-cmd.sh "./scripts/tools/generate-anchor-peer-update-channel-config.sh $ORG_ANCHOR_PEER_ADDRESS $CHANNEL_ID $PEER_GROUP_NAME"
    docker exec "$ORG_ANCHOR_PEER_ADDRESS" bash -c "./channel/update-channel-config.sh $ORG_ORDERER_ADDRESS $ORG_ANCHOR_PEER_ADDRESS $CHANNEL_ID"
done

