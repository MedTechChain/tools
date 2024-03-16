#!/usr/bin/env bash

FABRIC_DIR_PATH="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 && pwd -P)"
cd "$FABRIC_DIR_PATH"

source .env
source ../log.sh

export FABRIC_IMAGE_TAG

if [ ! -d "./.generated" ]; then
    error "Generated filed not found. Run ./infra-start.sh first"
    exit 1
fi

if [ -d "./.generated/.light" ]; then
    log "Running light mode"
    LIGHT="true"
fi

warn "SUDO REQUIRED: make sure the .generated folder belongs to the current user"
sudo chown -R $USER:$USER ./.generated

GEN_BUILD="$FABRIC_DIR_PATH/.generated/chaincode/build"
GEN_SRC="$FABRIC_DIR_PATH/.generated/chaincode/src/$CC_NAME"

mkdir -p "$GEN_SRC"
if [ $(ls "$GEN_SRC" | grep "$CC_VERSION") ]; then 
    error "Chaincode version already deployed. Please specify a new version (modify the .env file - increase version and sequence number)"
    exit 2
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
        exit 3
    fi
else
    if [[ ! "$1" =~ ^/ ]]; then
        echo "Error: Provided argument is not an absolute path"
        echo "Usage: ./cc-deploy.sh [<ABSOLUTE_CC_SRC_PATH>]"
        exit 4
    fi
    CHAINCODE_REPO_DIR_PATH="$1"
fi

cd "$CHAINCODE_REPO_DIR_PATH"

log "Build chaincode"

CONTAINER_NAME="chaincode-build"

# Mind that all provided commands should work
# with paths relative to the fabric direcotry 
# (see the bind mount)
mkdir -p "$GEN_BUILD"

docker run -it \
    --name "$CONTAINER_NAME" \
    --network host \
    --volume ".:/home/$USER" \
    --volume "$GEN_BUILD:/home/$USER/build" \
    --workdir "/home/$USER" \
    "gradle:8.6.0-jdk21" \
    bash -c "./gradlew shadowJar -x test"

docker rm -v "$CONTAINER_NAME" >/dev/null 2>&1


if [ $? -ne 0 ]; then
    error "Chaincode build failed with status $?"
    exit 2
fi

cd "$FABRIC_DIR_PATH"

mkdir -p "$GEN_SRC"
cp "$GEN_BUILD/libs/medtechchain.jar" "$GEN_SRC/medtechchain-$CC_VERSION.jar"

rm -rf "$GEN_BUILD"

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
