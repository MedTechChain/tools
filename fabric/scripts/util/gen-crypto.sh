#!/usr/bin/env bash

cd -- "$(dirname "$0")/../.." >/dev/null 2>&1

source ./scripts/util/log.sh

if [ ! -d "./crypto" ]; then
    log "Generate crypto material"
    ./scripts/util/tools-cmd.sh "cryptogen generate --config=./configs/cryptogen/crypto-config.yaml --output ./crypto"
else
    log "Crypto material detected. Skipping..."
fi