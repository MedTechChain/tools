#!/bin/bash

ORG_ORDERER_ADDRESS="$1"
ORG_PEER_ADDRESS="$2"
CHANNEL_ID="$3"

export CORE_PEER_MSPCONFIGPATH=/var/hyperledger/admin/msp

mkdir -p "/var/hyperledger/artifacts/channel/$ORG_PEER_ADDRESS/"
peer channel fetch config "/var/hyperledger/artifacts/channel/$ORG_PEER_ADDRESS/config_block.pb" \
    -c $CHANNEL_ID \
    -o "$ORG_ORDERER_ADDRESS:7050" --ordererTLSHostnameOverride "$ORG_ORDERER_ADDRESS" \
    --tls --cafile /var/hyperledger/orderer-tlscacert/orderer-tlscacert.pem
