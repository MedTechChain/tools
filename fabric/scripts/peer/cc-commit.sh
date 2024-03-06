#!/bin/bash

# $1 = peer id, e.g. peer1
# $2 = domain, e.g. medtechchain.nl
# $3 = CC_SEQUENCE, initially 1

CC_NAME="$1"
CC_VERSION="$2"
CC_SEQ="$3"

export CORE_PEER_MSPCONFIGPATH=/var/hyperledger/admin/msp

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


peer chaincode invoke \
    -C medtechchain \
    -o orderer.medtechchain.nl:7050 --ordererTLSHostnameOverride orderer.medtechchain.nl \
    --tls --cafile /var/hyperledger/orderer-tlscacert/tlsca.medtechchain.nl-cert.pem \
    -n "medtechchain" \
    -c '{"function":"medtechchain:CreateWatch","Args":["cf5a27f6-3875-46b6-a08f-4a842c3de7da","v0.0.3"]}'
