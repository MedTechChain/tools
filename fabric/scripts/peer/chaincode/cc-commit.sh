#!/bin/bash

ORDERER="$1"
CHANNEL_ID="$2"
CC_NAME="$3"
CC_VERSION="$4"
CC_SEQ="$5"

export CORE_PEER_MSPCONFIGPATH=/var/hyperledger/admin/msp

peer lifecycle chaincode checkcommitreadiness \
    -C "$CHANNEL_ID" \
    -n "$CC_NAME" -v "$CC_VERSION" --sequence "$CC_SEQ" \
    --tls --cafile /var/hyperledger/orderer-tlscacert/orderer-tlscacert.pem

peer lifecycle chaincode commit \
    -C "$CHANNEL_ID" \
    -o "$ORDERER:7050" --ordererTLSHostnameOverride $ORDERER \
    -n "$CC_NAME" -v "$CC_VERSION" --sequence "$CC_SEQ" \
    --tls --cafile /var/hyperledger/orderer-tlscacert/orderer-tlscacert.pem \
    --init-required