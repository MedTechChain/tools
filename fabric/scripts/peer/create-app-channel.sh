#!/bin/bash

export CORE_PEER_MSPCONFIGPATH=/var/hyperledger/admin/msp
export CORE_PEER_ADDRESS=peer0.medtechchain.nl:7051 

echo "peer0.medtechchain.nl creates the channel"
peer channel create \
    -f /var/hyperledger/app-channel/medtechchain-channel.tx \
    --outputBlock /var/hyperledger/app-channel/medtechchain.block \
    -o orderer.medtechchain.nl:7050 \
    --ordererTLSHostnameOverride orderer.medtechchain.nl \
    -c medtechchain \
    --tls \
    --cafile /var/hyperledger/orderer-tlscacert/tlsca.medtechchain.nl-cert.pem

echo "peer0.medtechchain.nl joins the channel"

peer channel join -b /var/hyperledger/app-channel/medtechchain.block

peer channel getinfo -c medtechchain

peer channel list \
    -o orderer.medtechchain.nl:7050 \
    --ordererTLSHostnameOverride orderer.medtechchain.nl \
    --tls \
    --cafile /var/hyperledger/orderer-tlscacert/tlsca.medtechchain.nl-cert.pem