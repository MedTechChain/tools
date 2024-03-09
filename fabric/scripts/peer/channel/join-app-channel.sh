#!/bin/bash

ORG_DOMAIN="$1"
ORG_ORDERER_ID="$2"
ORG_PEER_ID="$3"
CHANNEL_ID="$4"

export CORE_PEER_MSPCONFIGPATH=/var/hyperledger/admin/msp

peer channel join -b "/var/hyperledger/artifacts/channel/peer/peer0.medtechchain.nl/medtechchain.block"
