#!/usr/bin/env bash

FABRIC_DIR_PATH="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 && pwd -P)"
cd "$FABRIC_DIR_PATH"

source .env
source log.sh

export FABRIC_IMAGE_TAG

if [ ! -d "./.generated" ]; then
    error "Generated filed not found. Run ./infra-up.sh first"
    exit 1
fi

if [ -d "./.generated/.light" ]; then
    log "Running light mode"
    LIGHT="true"
fi

############### INIT ORG
# When setting up the infrastructure, one organization needs to initilize the app channel
# and deploy the chaincode. These variables are used to automate the process.
INIT_PEER="peer0.medtechchain.nl"
INIT_ORDERER="orderer0.medtechchain.nl"

############### CHANNEL
CHANNEL_ID="medtechchain"

############### BUILD
CHAINCODE_REPO_DIR_PATH="$FABRIC_DIR_PATH/../../chaincode"
if [ -z "$1" ]; then
    if [ ! -d "$CHAINCODE_REPO_DIR_PATH" ]; then
        echo "Error: No argument provided and $CHAINCODE_REPO_DIR_PATH not present (repo)"
        echo "Usage: ./cc-deploy.sh [<ABSOLUTE_CC_SRC_PATH>]"
        exit 1
    fi
else
    if [[ ! "$1" =~ ^/ ]]; then
        echo "Error: Provided argument is not an absolute path"
        echo "Usage: ./cc-deploy.sh [<ABSOLUTE_CC_SRC_PATH>]"
        exit 2
    fi
    CHAINCODE_REPO_DIR_PATH="$1"
fi

cd "$CHAINCODE_REPO_DIR_PATH"

log "Build chaincode"

./gradlew shadowJar -x test

if [ $? -ne 0 ]; then
    error "Chaincode build failed with status $?"
    exit 2
fi

cd "$FABRIC_DIR_PATH"

rm -rf "./.generated/chaincode/src/$CC_NAME"
cp -r "$CHAINCODE_REPO_DIR_PATH/build/libs" "./.generated/chaincode/src/$CC_NAME"

############### PACKAGE
log "Package chaincode"
docker exec "$INIT_PEER" bash -c "./chaincode/cc-package.sh $CC_NAME $CC_VERSION"

############### INSTALL
function peer_run {
    docker exec "$1" bash -c "$2"
}

log "Install chaincode"

peer_run "peer0.medtechchain.nl" "./chaincode/cc-install.sh $CC_NAME $CC_VERSION"
peer_run "peer0.medivale.nl" "./chaincode/cc-install.sh $CC_NAME $CC_VERSION"

if [ ! $LIGHT ]; then
    peer_run "peer0.healpoint.nl" "./chaincode/cc-install.sh $CC_NAME $CC_VERSION"
    peer_run "peer0.lifecare.nl" "./chaincode/cc-install.sh $CC_NAME $CC_VERSION"
fi

############### APPROVE
log "Approve chaincode"

peer_run "peer0.medtechchain.nl" "./chaincode/cc-approve.sh orderer0.medtechchain.nl $CHANNEL_ID $CC_NAME $CC_VERSION $CC_SEQ"
peer_run "peer0.medivale.nl" "./chaincode/cc-approve.sh orderer0.medivale.nl $CHANNEL_ID $CC_NAME $CC_VERSION $CC_SEQ"

if [ ! $LIGHT ]; then
    peer_run "peer0.healpoint.nl" "./chaincode/cc-approve.sh orderer0.healpoint.nl $CHANNEL_ID $CC_NAME $CC_VERSION $CC_SEQ"
    peer_run "peer0.lifecare.nl" "./chaincode/cc-approve.sh orderer0.lifecare.nl $CHANNEL_ID $CC_NAME $CC_VERSION $CC_SEQ"
fi

############### COMMIT
log "Commit chaincode"
peer_run "$INIT_PEER" "./chaincode/cc-commit.sh $INIT_ORDERER $CHANNEL_ID $CC_NAME $CC_VERSION $CC_SEQ"
