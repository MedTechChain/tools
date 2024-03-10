#!/bin/bash

CC_NAME="$1"
CC_VERSION="$2"

export CORE_PEER_MSPCONFIGPATH=/var/hyperledger/admin/msp

peer lifecycle chaincode install "/var/hyperledger/chaincode/pkg/${CC_NAME}_${CC_VERSION}.tar.gz"
