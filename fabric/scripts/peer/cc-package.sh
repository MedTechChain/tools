#!/bin/bash

export CORE_PEER_MSPCONFIGPATH=/var/hyperledger/admin/msp
export CORE_PEER_ADDRESS=peer0.medtechchain.nl:7051

CC_NAME="$1"
CC_VERSION="$2"

mkdir -p /var/hyperledger/cc-pkg
peer lifecycle chaincode package "/var/hyperledger/cc-pkg/${CC_NAME}_${CC_VERSION}.tar.gz" --path "/var/hyperledger/cc-src/$CC_NAME" --lang java --label "${CC_NAME}_${CC_VERSION}"