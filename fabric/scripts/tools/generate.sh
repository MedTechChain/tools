#!/bin/bash

FABRIC_DIR="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P)/../.."
cd "$FABRIC_DIR"

cryptogen generate --config=./configs/crypto/crypto-config.yaml --output ./.generated/crypto

configtxgen -configPath "./configs/configtx" \
            -profile MedTechChainGenesis \
            -channelID system-channel \
            -outputBlock "$FABRIC_DIR/.generated/genesis-block/medtechchain-genesis.block"

configtxgen -configPath "./configs/configtx" \
            -profile MedTechChainChannel \
            -channelID medtechchain \
            -outputCreateChannelTx "$FABRIC_DIR/.generated/channel-artifacts/peer/peer0.medtechchain.nl/medtechchain-channel.tx"

# Used to later mount configurations related to channel artifacts
for domain in "medivale.nl" "healpoint.nl" "lifecare.nl"; do
    for peer in "peer0" "peer1" "peer2"; do 
        mkdir -p "$FABRIC_DIR/.generated/channel-artifacts/peer/$peer.$domain"
    done
done