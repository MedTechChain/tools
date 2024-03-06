#!/bin/bash

FABRIC_DIR="$(
    cd -- "$(dirname "$0")" >/dev/null 2>&1
    pwd -P
)"
cd "$FABRIC_DIR"

docker-compose-up() {
    docker-compose --project-directory "$FABRIC_DIR" -p "$1" \
        -f "./configs/docker/$1.docker-compose.yaml" \
        up -d
}

create-docker-network() {
    if [ ! "$(docker network ls | grep "$1")" ]; then
        docker network create --driver bridge "$1"
    fi
}

echo "Generate configurations and crypto material"
./tools-cmd.sh "./clean.sh; ./generate.sh"

echo "Set up docker networks and run containers"
for network in "fabric-tools" "internet" "medtechchain" "medivale" "healpoint" "lifecare"; do
    create-docker-network "$network"
done

for company in "medtechchain" "medivale" "healpoint" "lifecare"; do
    docker-compose-up "$company"
done

echo "Sleep until containers start..."
sleep 10

# MedTech Chain
echo "peer0.medtechchain.nl creates app channel"
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
cd ./explorer
docker-compose up -d
cd ..
