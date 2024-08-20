#!/usr/bin/env bash

FABRIC_DIR_PATH="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 && pwd -P)"
cd "$FABRIC_DIR_PATH"

source .env
source ./scripts/util/log.sh

export FABRIC_IMAGE_TAG

############### VARIABLES
CC_NAME="medtechchain"
CC_VERSION="$1"
CC_SEQ="$2"
CHANNEL_ID="medtechchain"

if [ ! -d "./.generated" ]; then
    error "Generated filed not found. Run ./infra-start.sh first"
    exit 1
fi

GEN_BUILD="$FABRIC_DIR_PATH/.generated/chaincode/build"
GEN_PKG="$FABRIC_DIR_PATH/.generated/chaincode/pkg"

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: ./cc-deploy-external.sh <CC_VERSION> <CC_SEQ>"
    exit 2
fi

cd "$FABRIC_DIR_PATH"

warn "SUDO REQUIRED: make sure the .generated folder belongs to the current user"
sudo chown -R $USER:$USER ./.generated

cp -TR  "./chaincode" "$GEN_PKG"

cd "$GEN_PKG"
echo '{"type":"ccaas","label":"'"${CC_NAME}_${CC_VERSION}"'"}' > metadata.json
tar czvf code.tar.gz connection.json
tar czvf "${CC_NAME}_${CC_VERSION}.tar.gz" metadata.json code.tar.gz
cd "$FABRIC_DIR_PATH"

############### PACKAGE & INSTALL
function peer_exec {
    docker exec "$1" bash -c "$2"
}

peer_exec "peer0.medtechchain.nl" "./chaincode/cc-install.sh $CC_NAME $CC_VERSION"
peer_exec "peer0.healpoint.nl" "./chaincode/cc-install.sh $CC_NAME $CC_VERSION"
peer_exec "peer0.lifecare.nl" "./chaincode/cc-install.sh $CC_NAME $CC_VERSION"

############### APPROVE
log "Approve chaincode"

peer_exec "peer0.medtechchain.nl" "./chaincode/cc-approve.sh orderer0.medtechchain.nl $CHANNEL_ID $CC_NAME $CC_VERSION $CC_SEQ"
peer_exec "peer0.healpoint.nl" "./chaincode/cc-approve.sh orderer0.healpoint.nl $CHANNEL_ID $CC_NAME $CC_VERSION $CC_SEQ"
peer_exec "peer0.lifecare.nl" "./chaincode/cc-approve.sh orderer0.lifecare.nl $CHANNEL_ID $CC_NAME $CC_VERSION $CC_SEQ"

############### COMMIT
log "Commit chaincode"
peer_exec "peer0.medtechchain.nl" "./chaincode/cc-commit.sh orderer0.medtechchain.nl $CHANNEL_ID $CC_NAME $CC_VERSION $CC_SEQ"

warn "COPY THE CHAINCODE PACKAGE ID (from logs) INTO THE CHAINCODE INSTANCE CONFIGURATION"
log "Waiting... (press any key to continue after running the chaincode containers - wait for containers to warm up)"

read
log "Do not hurry...."
sleep 5

############### INIT
peer_exec "peer0.medtechchain.nl" "./chaincode/cc-init.sh orderer0.medtechchain.nl $CHANNEL_ID $CC_NAME"