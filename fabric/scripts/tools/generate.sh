#!/bin/bash

FABRIC_DIR="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P)/../.."
cd "$FABRIC_DIR"

cryptogen generate --config=./configs/crypto/crypto-config.yaml --output ./.generated/crypto

configtxgen -configPath "./configs/configtx" \
            -profile MedTechChainGenesis \
            -channelID system-channel \
            -outputBlock "$FABRIC_DIR/.generated/configtx/genesis/medtechchain-genesis.block"

configtxgen -configPath "./configs/configtx" \
            -profile MedTechChainChannel \
            -channelID medtechchain \
            -outputCreateChannelTx "$FABRIC_DIR/.generated/configtx/app-channel/medtechchain-channel.tx"

