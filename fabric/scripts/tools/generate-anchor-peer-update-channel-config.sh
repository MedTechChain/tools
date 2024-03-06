#!/bin/bash

# $1 = peer id, e.g. peer1
# $2 = domain, e.g. medtechchain.nl

FABRIC_DIR="$(
    cd -- "$(dirname "$0")" >/dev/null 2>&1
    pwd -P
)/../.."
cd "$FABRIC_DIR"

cd "./.generated/channel-artifacts/peer/$1.$2/"

configtxlator proto_decode --input config_block.pb --type common.Block --output config_block.json
jq '.data.data[0].payload.data.config' config_block.json >config.json

cp config.json config_copy.json

jq '.channel_group.groups.Application.groups.'"$3"'.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "'"$1.$2"'","port": 7051}]},"version": "0"}}' config_copy.json >modified_config.json

configtxlator proto_encode --input config.json --type common.Config --output config.pb
configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb
configtxlator compute_update --channel_id medtechchain --original config.pb --updated modified_config.pb --output config_update.pb

configtxlator proto_decode --input config_update.pb --type common.ConfigUpdate --output config_update.json
echo '{"payload":{"header":{"channel_header":{"channel_id":"medtechchain", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . >config_update_in_envelope.json
configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope --output config_update_in_envelope.pb
