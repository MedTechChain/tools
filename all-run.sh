#!/usr/bin/env bash

cd -- "$(dirname "$0")"

source ./log.sh

if [ "$1" == "--light" ]; then
    log "Running light mode"
    LIGHT="true"
elif [ -n "$1" ]; then
    error "Usage: ./$0 [--light] [SMTP_PASSWORD]"
    exit 1  
fi

./fabric/infra-start.sh "$1"
warn "SUDO REQUIRED: make sure the .generated folder belongs to the current user"
sudo chown -R $USER:$USER ./fabric/.generated
./fabric/cc-deploy.sh

cd ..

./backend/scripts/copy-crypto.sh

if [ -z "$2" ]; then
    export SMTP_PASSWORD=""
    PROFILE=dev
else
    export SMTP_PASSWORD="$2"
    PROFILE=demo
fi

docker-compose --profile $PROFILE -f ./backend/docker-compose.yaml -p medtechchain-ums-be up -d --build

./hospital-server/scripts/copy-crypto.sh

PROFILE=default
if [ $LIGHT ]; then
    PROFILE=light
fi
docker-compose --profile $PROFILE -f ./hospital-server/docker-compose.yaml -p medtechchain-hpt up -d --build

docker-compose -f ./frontend/docker-compose.yaml -p medtechchain-ums-fe up -d --build

docker restart explorer.medtechchain.nl