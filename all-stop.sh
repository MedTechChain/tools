#!/usr/bin/env bash

cd -- "$(dirname "$0")/.."

if [ "$1" = "--clean" ]; then
    VOLUME_FLAG="-v"
fi

export SMTP_PASSWORD=""

docker-compose --profile dev --profile demo -f ./backend/docker-compose.yaml -p medtechchain-ums-be down $VOLUME_FLAG
docker-compose --profile dev --profile demo -f ./frontend/docker-compose.yaml -p medtechchain-ums-fe down $VOLUME_FLAG
docker-compose --profile medivale --profile healpoint --profile lifecare -f ./hospital-server/docker-compose.yaml -p medtechchain-hpt down $VOLUME_FLAG


if [ "$1" = "--clean" ]; then
    ./dev-tools/fabric/infra-clean.sh
else
    ./dev-tools/fabric/infra-stop.sh
fi
