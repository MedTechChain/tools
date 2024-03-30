#!/usr/bin/env bash

cd -- "$(dirname "$0")/.."

if [ "$1" = "--clean" ]; then
    VOLUME_FLAG="-v" 
fi

export SMTP_PASSWORD=""

docker-compose --profile dev --profile demo -f ./backend/docker-compose.yaml -p medtechchain-ums-be down $VOLUME_FLAG

if [ "$1" = "--clean" ]; then
    ./tools/fabric/infra-clean.sh
else
    ./tools/fabric/infra-stop.sh
fi