#!/bin/bash

FABRIC_DIR="$(
    cd -- "$(dirname "$0")" >/dev/null 2>&1
    pwd -P
)"
cd "$FABRIC_DIR"

docker-compose-down() {
    docker-compose --project-directory "$FABRIC_DIR" -p "$1" \
        -f "./configs/docker/$1.docker-compose.yaml" \
        down -v
}

delete-docker-network() {
    if [ "$(docker network ls | grep "$1")" ]; then
        docker network rm "$1"
    fi
}

cd ./explorer
docker-compose down -v
cd ..

for network in "medtechchain" "medivale" "healpoint" "lifecare"; do
    docker-compose-down "$network"
done

./tools-cmd.sh "./clean.sh"

for network in "fabric-tools" "internet" "medtechchain" "medivale" "healpoint" "lifecare"; do
    delete-docker-network "$network"
done

