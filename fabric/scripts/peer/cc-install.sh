#!/bin/bash

# $1 = peer id, e.g. peer1
# $2 = domain, e.g. medtechchain.nl
# $3 = CC_NAME
# $4 = CC_VERSION

CC_NAME="$3"
CC_VERSION="$4"

export CORE_PEER_MSPCONFIGPATH=/var/hyperledger/admin/msp

peer lifecycle chaincode install "/var/hyperledger/cc-pkg/${CC_NAME}_${CC_VERSION}.tar.gz"
