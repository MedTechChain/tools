#!/bin/bash

# $1 = peer id, e.g. peer1
# $2 = domain, e.g. medtechchain.nl

SCRIPT_DIR="$(
    cd -- "$(dirname "$0")" >/dev/null 2>&1
    pwd -P
)"
cd "$SCRIPT_DIR"

export CORE_PEER_MSPCONFIGPATH=/var/hyperledger/admin/msp

echo "$1.$2 fetches the channel tx block"

peer channel fetch config "/var/hyperledger/channel-artifacts/config_block.pb" \
    -c medtechchain \
    -o "orderer.$2:7050" --ordererTLSHostnameOverride "orderer.$2" \
    --tls --cafile "/var/hyperledger/orderer-tlscacert/tlsca.$2-cert.pem"
