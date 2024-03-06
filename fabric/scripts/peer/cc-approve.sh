#!/bin/bash

# $1 = peer id, e.g. peer1
# $2 = domain, e.g. medtechchain.nl
# $3 = CC_NAME
# $4 = CC_VERSION
# $5 = CC_SEQUENCE, initially 1

CC_NAME="$3"
CC_VERSION="$4"
CC_SEQ="$5"

export CORE_PEER_MSPCONFIGPATH=/var/hyperledger/admin/msp
export CORE_PEER_ADDRESS="$1.$2:7051"

CC_PACKAGE_ID="$(peer lifecycle chaincode queryinstalled | awk -F', ' '/Label: '"${CC_NAME}_${CC_VERSION}"'$/{ split($1, a, ": "); print a[2] }')"

peer lifecycle chaincode approveformyorg \
    -C medtechchain \
    -o "orderer.$2:7050" --ordererTLSHostnameOverride "orderer.$2" \
    --package-id $CC_PACKAGE_ID -n "$CC_NAME" -v "$CC_VERSION" --sequence "$CC_SEQ" \
    --tls --cafile "/var/hyperledger/orderer-tlscacert/tlsca.$2-cert.pem"
