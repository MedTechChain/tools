#!/bin/bash

export CORE_PEER_MSPCONFIGPATH=/var/hyperledger/admin/msp

echo "peer0.medtechchain.nl creates the channel"
peer channel create -f /var/hyperledger/channel-artifacts/medtechchain-channel.tx \
    --outputBlock /var/hyperledger/channel-artifacts/medtechchain.block \
    -c medtechchain \
    -o orderer.medtechchain.nl:7050 --ordererTLSHostnameOverride orderer.medtechchain.nl \
    --tls --cafile /var/hyperledger/orderer-tlscacert/tlsca.medtechchain.nl-cert.pem

echo "peer0.medtechchain.nl joins the channel"

peer channel join -b /var/hyperledger/channel-artifacts/medtechchain.block

peer channel getinfo -c medtechchain

peer channel list \
    -o orderer.medtechchain.nl:7050 --ordererTLSHostnameOverride orderer.medtechchain.nl \
    --tls --cafile /var/hyperledger/orderer-tlscacert/tlsca.medtechchain.nl-cert.pem
