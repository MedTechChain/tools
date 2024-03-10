#!/bin/bash

INIT_PEER_ADDRESS="$1"
CHANNEL_ID="$2"

export CORE_PEER_MSPCONFIGPATH=/var/hyperledger/admin/msp

peer channel join -b "/var/hyperledger/artifacts/channel/$INIT_PEER_ADDRESS/$CHANNEL_ID.block"
