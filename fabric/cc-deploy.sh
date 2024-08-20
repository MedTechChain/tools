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

warn "SUDO REQUIRED: make sure the .generated folder belongs to the current user"
sudo chown -R $USER:$USER ./.generated

GEN_BUILD="$FABRIC_DIR_PATH/.generated/chaincode/build"
GEN_SRC="$FABRIC_DIR_PATH/.generated/chaincode/src/$CC_NAME"

mkdir -p "$GEN_SRC"
if [ $(ls "$GEN_SRC" | grep "$CC_VERSION") ]; then 
    error "Chaincode version already deployed. Please specify a new version (modify the .env file - increase version and sequence number)"
    exit 2
fi

############### BUILD
CHAINCODE_REPO_DIR_PATH="$FABRIC_DIR_PATH/../../chaincode"
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: ./cc-deploy.sh <CC_VERION> <CC_SEQ> [<ABSOLUTE_CC_SRC_PATH>]"
    exit 3
fi

if [ -z "$3" ]; then
    if [ ! -d "$CHAINCODE_REPO_DIR_PATH" ]; then
        echo "Usage: ./cc-deploy.sh <CC_VERION> <CC_SEQ> [<ABSOLUTE_CC_SRC_PATH>]"
        exit 4
    fi
else
    if [[ ! "$3" =~ ^/ ]]; then
        echo "Error: Provided argument is not an absolute path"
        echo "Usage: ./cc-deploy.sh <CC_VERION> <CC_SEQ> [<ABSOLUTE_CC_SRC_PATH>]"
        exit 5
    fi
    CHAINCODE_REPO_DIR_PATH="$1"
fi

cd "$CHAINCODE_REPO_DIR_PATH"

log "Build chaincode"

# Mind that all provided commands should work
# with paths relative to the fabric direcotry 
# (see the bind mount)
mkdir -p "$GEN_BUILD"

docker run --rm -it \
    --network host \
    --volume ".:/home/$USER" \
    --volume "$GEN_BUILD:/home/$USER/build" \
    --workdir "/home/$USER" \
    "gradle:8.6.0-jdk21" \
    bash -c "./gradlew shadowJar -x test"


if [ $? -ne 0 ]; then
    error "Chaincode build failed with status $?"
    exit 6
fi

cd "$FABRIC_DIR_PATH"

mkdir -p "$GEN_SRC"
cp "$GEN_BUILD/libs/medtechchain.jar" "$GEN_SRC/medtechchain-$CC_VERSION.jar"

sudo chown -R $USER:$USER ./.generated
rm -rf "$GEN_BUILD"

############### PACKAGE
log "Package chaincode"
docker exec peer0.medtechchain.nl bash -c "./chaincode/cc-package.sh $CC_NAME $CC_VERSION"

############### INSTALL
function peer_exec {
    docker exec "$1" bash -c "$2"
}

log "Install chaincode"

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

############### INIT
peer_exec "peer0.medtechchain.nl" "./chaincode/cc-init.sh orderer0.medtechchain.nl $CHANNEL_ID $CC_NAME"