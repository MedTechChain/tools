#!/bin/bash

ORDERER="$1"
CHANNEL_ID="$2"
CC_NAME="$3"

export CORE_PEER_MSPCONFIGPATH=/var/hyperledger/admin/msp


peer chaincode invoke  \
    -C "$CHANNEL_ID" \
    -o "$ORDERER:7050" --ordererTLSHostnameOverride $ORDERER \
    -n "$CC_NAME" \
    --tls --cafile /var/hyperledger/orderer-tlscacert/orderer-tlscacert.pem \
    --isInit \
    -c '{"Args":["platformconfig:Init"]}'