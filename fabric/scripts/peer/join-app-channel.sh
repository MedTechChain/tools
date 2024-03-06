#!/bin/bash

# $1 = peer id, e.g. peer1
# $2 = domain, e.g. medtechchain.nl

export CORE_PEER_MSPCONFIGPATH=/var/hyperledger/admin/msp
export CORE_PEER_ADDRESS="$1.$2:7051"

echo "$1.$2 fetches the channel tx block"
mkdir -p "/var/hyperledger/channel-artifacts"
peer channel fetch 0 "/var/hyperledger/channel-artifacts/medtechchain.block" \
    -c medtechchain \
    -o "orderer.$2:7050" --ordererTLSHostnameOverride "orderer.$2" \
    --tls --cafile "/var/hyperledger/orderer-tlscacert/tlsca.$2-cert.pem"

echo "$1.$2 joins the channel"
peer channel join -b /var/hyperledger/channel-artifacts/medtechchain.block
