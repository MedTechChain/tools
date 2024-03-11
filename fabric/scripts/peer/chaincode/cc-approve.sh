#!/bin/bash

ORDERER="$1"
CHANNEL_ID="$2"
CC_NAME="$3"
CC_VERSION="$4"
CC_SEQ="$5"

export CORE_PEER_MSPCONFIGPATH=/var/hyperledger/admin/msp

CC_PACKAGE_ID="$(peer lifecycle chaincode queryinstalled | awk -F', ' '/Label: '"${CC_NAME}_${CC_VERSION}"'$/{ split($1, a, ": "); print a[2] }')"

peer lifecycle chaincode approveformyorg \
    -C "$CHANNEL_ID" \
    -o "$ORDERER:7050" --ordererTLSHostnameOverride "$ORDERER" \
    --package-id $CC_PACKAGE_ID -n "$CC_NAME" -v "$CC_VERSION" --sequence "$CC_SEQ" \
    --tls --cafile /var/hyperledger/orderer-tlscacert/orderer-tlscacert.pem
