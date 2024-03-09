#!/bin/bash

SCRIPT_DIR="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 && pwd -P)"
cd "$SCRIPT_DIR"

# Changes when the script is moved
FABRIC_DIR="$SCRIPT_DIR"

source "$FABRIC_DIR/scripts/commons.sh"
source "$FABRIC_DIR/.env"

DEV_TOOLS_DIR="$FABRIC_DIR/.."

if [ -z "$1" ]; then
    if [ -d "$DEV_TOOLS_DIR/../chaincode" ]; then
        CC_SRC_PATH="$DEV_TOOLS_DIR/../chaincode"
    else
        echo "Error: No argument provided and $DEV_TOOLS_DIR/../chaincode not present (repo)"
        echo "Usage: ./cc-deploy.sh [<ABSOLUTE_CC_SRC_PATH>]"
        exit 1
    fi
else
    if [[ ! "$1" =~ ^/ ]]; then
        echo "Error: Provided argument is not an absolute path"
        echo "Usage: ./cc-deploy.sh [<ABSOLUTE_CC_SRC_PATH>]"
        exit 2
    fi
    CC_SRC_PATH="$1"
fi

cd "$CC_SRC_PATH"

./gradlew shadowJar -x test

cd "$FABRIC_DIR"

GEN_DIR="./.generated"

GEN_CC_PKG_DIR="$GEN_DIR/cc-pkg"
GEN_CC_SRC_DIR="$GEN_DIR/cc-src"

rm -rf "$GEN_CC_SRC_DIR/$CC_NAME"
cp -r "$CC_SRC_PATH/build/libs" "$GEN_CC_SRC_DIR/$CC_NAME"

sleep 1

docker exec "$INIT_PEER_ID" bash -c "./chaincode/cc-package.sh $CC_NAME $CC_VERSION"

for peer_id in ${ORG_PEER_IDS[@]}; do
    docker exec "$peer_id" bash -c "./chaincode/cc-install.sh $CC_NAME $CC_VERSION"
done

for name in ${ORG_NAMES[@]}; do
    ORG_DOMAIN=${ORG_DOMAINS[$name]}
    ORG_ORDERER_ID=${ORG_ORDERER_IDS[$name,0]}

    for i in $(seq 0 $((NUM_OF_PEERS - 1))); do
        ORG_PEER_ID=${ORG_ANCHOR_PEER_IDS[$name,$i]}
        docker exec "$ORG_PEER_ID" bash -c "./chaincode/cc-approve.sh $ORG_DOMAIN $ORG_ORDERER_ID $CHANNEL_ID $CC_NAME $CC_VERSION $CC_SEQ"
    done
done

docker exec "$INIT_PEER_ID" bash -c "./chaincode/cc-commit.sh $INIT_ORG_DOMAIN $INIT_ORDERER_ID $CHANNEL_ID $CC_NAME $CC_VERSION $CC_SEQ"
