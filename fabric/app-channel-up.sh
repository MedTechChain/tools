#!/bin/bash

APP_CHANNEL_PEER_CONTAINER=peer0.medtechchain.nl

echo "Creating the application channel via $APP_CHANNEL_PEER_CONTAINER"

docker exec $APP_CHANNEL_PEER_CONTAINER bash -c \
    "peer channel create \
    -f /var/hyperledger/app-channel/medtechchain-channel.tx \
    --outputBlock /var/hyperledger/app-channel/medtechchain.block \
    -o orderer.medtechchain.nl:7050 \
    -c medtechchain \
    --tls \
    --cafile /var/hyperledger/orderer-tlscacert/tlsca.medtechchain.nl-cert.pem"