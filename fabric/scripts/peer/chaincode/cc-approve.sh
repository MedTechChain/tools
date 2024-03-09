#!/bin/bash

ORG_DOMAIN="$1"
ORG_ORDERER_ID="$2"
CHANNEL_ID="$3"
CC_NAME="$4"
CC_VERSION="$5"
CC_SEQ="$6"

export CORE_PEER_MSPCONFIGPATH=/var/hyperledger/admin/msp

CC_PACKAGE_ID="$(peer lifecycle chaincode queryinstalled | awk -F', ' '/Label: '"${CC_NAME}_${CC_VERSION}"'$/{ split($1, a, ": "); print a[2] }')"

peer lifecycle chaincode approveformyorg \
    -C "$CHANNEL_ID" \
    -o "$ORG_ORDERER_ID:7050" --ordererTLSHostnameOverride "$ORG_ORDERER_ID" \
    --package-id $CC_PACKAGE_ID -n "$CC_NAME" -v "$CC_VERSION" --sequence "$CC_SEQ" \
    --tls --cafile "/var/hyperledger/orderer-tlscacert/tlsca.$ORG_DOMAIN-cert.pem"
