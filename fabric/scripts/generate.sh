#!/bin/bash

FABRIC_DIR="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P)/.."
cd "$FABRIC_DIR"

cryptogen generate --config=./configs/crypto/crypto-config.yaml --output ./.generated/crypto

configtxgen -configPath "./configs/configtx" \
            -profile HealthBlocks \
            -channelID healthnlocks_channel \
            -outputBlock "$FABRIC_DIR/.generated/configtx/genesis/healthblocks-genesis.block"

configtxgen -configPath "./configs/configtx" \
            -profile HealthBlocks \
            -channelID healthnlocks_channel \
            -outputCreateChannelTx "$FABRIC_DIR/.generated/configtx/channel/healthblocks-channel.tx"

