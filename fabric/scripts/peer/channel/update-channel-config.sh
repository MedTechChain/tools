#!/bin/bash

ORG_DOMAIN="$1"
ORG_ORDERER_ID="$2"
ORG_PEER_ID="$3"
CHANNEL_ID="$4"

export CORE_PEER_MSPCONFIGPATH=/var/hyperledger/admin/msp

peer channel signconfigtx -f "/var/hyperledger/artifacts/channel/peer/$ORG_PEER_ID/config_update_in_envelope.pb"

peer channel update -f "/var/hyperledger/artifacts/channel/peer/$ORG_PEER_ID/config_update_in_envelope.pb" \
    -c $CHANNEL_ID \
    -o "$ORG_ORDERER_ID:7050" --ordererTLSHostnameOverride "$ORG_ORDERER_ID" \
    --tls --cafile "/var/hyperledger/orderer-tlscacert/tlsca.$ORG_DOMAIN-cert.pem"
