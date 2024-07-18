#!/usr/bin/env bash

cd -- "$(dirname "$0")/../.." >/dev/null 2>&1

source ./scripts/util/log.sh

SYSTEM_CHANNEL="system-channel"
CHANNEL_ID="medtechchain"
GENESIS_PROFILE_NAME="MedTechChainGenesis"
APP_CHANNEL_PROFILE_NAME="MedTechChainChannel"

############### GENESIS BLOCK
if [ ! -f "./artifacts/genesis/genesis.block" ]; then
    log "Generate genesis block"

    ./scripts/util/tools-cmd.sh "configtxgen \
        -configPath ./configs/configtx \
        -profile $GENESIS_PROFILE_NAME \
        -channelID $SYSTEM_CHANNEL \
        -outputBlock ./artifacts/genesis/genesis.block"

else
    log "Genesis block detected. Skipping..."
fi

if [ ! -f "./artifacts/channel/$CHANNEL_ID-channel.tx" ]; then
    log "Generate channel config transaction"

    ./scripts/util/tools-cmd.sh "configtxgen \
        -configPath ./configs/configtx  \
        -profile $APP_CHANNEL_PROFILE_NAME \
        -channelID $CHANNEL_ID \
        -outputCreateChannelTx ./artifacts/channel/$CHANNEL_ID-channel.tx"

else
    log "Channel config transaction detected. Skipping..."
fi