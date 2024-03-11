#!/bin/bash

ORDERER="$1"
PEER="$2"
CHANNEL_ID="$3"

export CORE_PEER_MSPCONFIGPATH=/var/hyperledger/admin/msp

peer channel signconfigtx -f "/var/hyperledger/artifacts/channel/$PEER/config_update_in_envelope.pb"

peer channel update -f "/var/hyperledger/artifacts/channel/$PEER/config_update_in_envelope.pb" \
    -c $CHANNEL_ID \
    -o "$ORDERER:7050" --ordererTLSHostnameOverride "$ORDERER" \
    --tls --cafile /var/hyperledger/orderer-tlscacert/orderer-tlscacert.pem
