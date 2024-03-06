#!/bin/bash

# $1 = peer id, e.g. peer1
# $2 = domain, e.g. medtechchain.nl

CC_NAME="$1"
CC_VERSION="$2"

export CORE_PEER_MSPCONFIGPATH=/var/hyperledger/admin/msp
export CORE_PEER_ADDRESS=peer0.medtechchain.nl:7051

mkdir -p /var/hyperledger/cc-pkg
peer lifecycle chaincode package "/var/hyperledger/cc-pkg/${CC_NAME}_${CC_VERSION}.tar.gz" --path "/var/hyperledger/cc-src/$CC_NAME" --lang java --label "${CC_NAME}_${CC_VERSION}"