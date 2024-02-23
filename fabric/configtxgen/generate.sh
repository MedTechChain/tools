#!/bin/bash

SCRIPT_PATH="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P)"
FABRIC_FOLDER_PATH="$SCRIPT_PATH/.."
cd "$FABRIC_FOLDER_PATH"

./cryptogen/clean.sh
./cryptogen/generate.sh

configtxgen -configPath "$SCRIPT_PATH/configs" \
            -profile HealthBlocks \
            -channelID ordererchannel \
            -outputBlock "$FABRIC_FOLDER_PATH/.generated/configtxgen/healthblocks-genesis.block"

configtxgen -configPath "$SCRIPT_PATH/configs" \
            -profile HealthBlocks \
            -channelID ordererchannel \
            -outputCreateChannelTx "$FABRIC_FOLDER_PATH/.generated/configtxgen/healthblocks-channel.tx"

