#!/usr/bin/env bash

cd -- "$(dirname "$0")"

source ./log.sh

./fabric/infra-start.sh "$1"
warn "SUDO REQUIRED: make sure the .generated folder belongs to the current user"
sudo chown -R $USER:$USER ./fabric/.generated
./fabric/cc-deploy.sh

cd ..

if [ -z "$2" ]; then
    export SMTP_PASSWORD=""
    PROFILE=dev
else
    export SMTP_PASSWORD="$2"
    PROFILE=demo
fi

./backend/scripts/copy-crypto.sh

docker-compose --profile $PROFILE -f ./backend/docker-compose.yaml -p medtechchain-ums-be up -d --build

docker restart explorer.medtechchain.nl