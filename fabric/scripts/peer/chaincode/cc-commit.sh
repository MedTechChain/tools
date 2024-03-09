#!/bin/bash

ORG_DOMAIN="$1"
ORG_ORDERER_ID="$2"
CHANNEL_ID="$3"
CC_NAME="$4"
CC_VERSION="$5"
CC_SEQ="$6"

export CORE_PEER_MSPCONFIGPATH=/var/hyperledger/admin/msp

peer lifecycle chaincode checkcommitreadiness \
    -C "$CHANNEL_ID" \
    -n "$CC_NAME" -v "$CC_VERSION" --sequence "$CC_SEQ" \
    --tls --cafile /var/hyperledger/orderer-tlscacert/tlsca.$ORG_DOMAIN-cert.pem 

peer lifecycle chaincode commit \
    -C "$CHANNEL_ID" \
    -o "$ORG_ORDERER_ID:7050" --ordererTLSHostnameOverride $ORG_ORDERER_ID \
    -n "$CC_NAME" -v "$CC_VERSION" --sequence "$CC_SEQ" \
    --tls --cafile /var/hyperledger/orderer-tlscacert/tlsca.$ORG_DOMAIN-cert.pem