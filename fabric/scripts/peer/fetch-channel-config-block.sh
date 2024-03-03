#!/bin/bash

# $1 = peer id, e.g. peer1
# $2 = domain, e.g. medtechchain.nl

SCRIPT_DIR="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P)"
cd "$SCRIPT_DIR"

export CORE_PEER_MSPCONFIGPATH=/var/hyperledger/admin/msp
export CORE_PEER_ADDRESS="$1.$2:7051"

echo "$1.$2 fetches the channel tx block"

peer channel fetch config "/var/hyperledger/channel-artifacts/config_block.pb" \
    -o "orderer.$2:7050" \
    --ordererTLSHostnameOverride "orderer.$2" \
    -c medtechchain \
    --tls \
    --cafile "/var/hyperledger/orderer-tlscacert/tlsca.$2-cert.pem"
