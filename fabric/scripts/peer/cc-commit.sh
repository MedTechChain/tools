#!/bin/bash

# $1 = peer id, e.g. peer1
# $2 = domain, e.g. medtechchain.nl
# $3 = CC_SEQUENCE, initially 1

CC_NAME="$1"
CC_VERSION="$2"
CC_SEQ="$3"

export CORE_PEER_MSPCONFIGPATH=/var/hyperledger/admin/msp
export CORE_PEER_ADDRESS=peer0.medtechchain.nl:7051

peer lifecycle chaincode checkcommitreadiness \
    -C medtechchain \
    -n "$CC_NAME" -v "$CC_VERSION" --sequence "$CC_SEQ" \
    --tls --cafile /var/hyperledger/orderer-tlscacert/tlsca.medtechchain.nl-cert.pem 

peer lifecycle chaincode commit \
    -C medtechchain \
    -o orderer.medtechchain.nl:7050 --ordererTLSHostnameOverride orderer.medtechchain.nl \
    -n "$CC_NAME" -v "$CC_VERSION" --sequence "$CC_SEQ" \
    --tls --cafile /var/hyperledger/orderer-tlscacert/tlsca.medtechchain.nl-cert.pem

peer lifecycle chaincode querycommitted \
    -C medtechchain \
    -o orderer.medtechchain.nl:7050 --ordererTLSHostnameOverride orderer.medtechchain.nl \
    -n "$CC_NAME" \
    --tls --cafile /var/hyperledger/orderer-tlscacert/tlsca.medtechchain.nl-cert.pem