#!/bin/bash

ORDERER="$1"
PEER="$2"
CHANNEL_ID="$3"

export CORE_PEER_MSPCONFIGPATH=/var/hyperledger/admin/msp

mkdir -p "/var/hyperledger/artifacts/channel/$PEER/"
peer channel fetch config "/var/hyperledger/artifacts/channel/$PEER/config_block.pb" \
    -c $CHANNEL_ID \
    -o "$ORDERER:7050" --ordererTLSHostnameOverride "$ORDERER" \
    --tls --cafile /var/hyperledger/orderer-tlscacert/orderer-tlscacert.pem
