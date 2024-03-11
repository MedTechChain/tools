#!/bin/bash

INIT_PEER="$1"
CHANNEL_ID="$2"

export CORE_PEER_MSPCONFIGPATH=/var/hyperledger/admin/msp

peer channel join -b "/var/hyperledger/artifacts/channel/$INIT_PEER/$CHANNEL_ID.block"
