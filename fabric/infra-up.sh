#!/bin/bash

FABRIC_DIR="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P)"
cd "$FABRIC_DIR"

docker-compose-up() {
    docker-compose --project-directory $FABRIC_DIR -p "$1" \
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
    create-docker-network $network
done


for company in "medtechchain" "medivale" "healpoint" "lifecare"; do
    docker-compose-up $company
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


echo "Start Explorer..."
sleep 10
cd ./explorer
docker-compose up -d
cd ..
