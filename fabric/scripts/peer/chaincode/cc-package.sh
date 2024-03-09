#!/bin/bash

CC_NAME="$1"
CC_VERSION="$2"

export CORE_PEER_MSPCONFIGPATH=/var/hyperledger/admin/msp

mkdir -p /var/hyperledger/cc-pkg
peer lifecycle chaincode package "/var/hyperledger/cc-pkg/${CC_NAME}_${CC_VERSION}.tar.gz" --path "/var/hyperledger/cc-src/$CC_NAME" --lang java --label "${CC_NAME}_${CC_VERSION}"