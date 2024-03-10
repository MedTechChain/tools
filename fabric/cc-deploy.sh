#!/usr/bin/env bash

if ! docker info >/dev/null 2>&1; then
    echo "Error: Docker is not running"
    exit 1
fi

# Many environment variable are read from this script.
# Refer to this file whenever you want to find the value
# or particular variables.
source .env
source ./env.sh
source ./paths.sh

export FABRIC_IMAGE_TAG

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

############################################################################################################################################
echo -e "\xE2\x9C\x94 >>> BUILD CHAINCODE <<<"

./gradlew shadowJar -x test

if [ $? -ne 0 ]; then
    echo ">>> ERROR: chaincode build failed with status $?"
    exit 1
fi

cd "$FABRIC_DIR_PATH"

rm -rf "$GEN_CHAINCODE_SOURCE_PATH/$CC_NAME"
cp -r "$CHAINCODE_REPO_DIR_PATH/build/libs" "$GEN_CHAINCODE_SOURCE_PATH/$CC_NAME"

############################################################################################################################################
echo -e "\xE2\x9C\x94 >>> PACKAGE CHAINCODE <<<"
docker exec "$INIT_PEER_ADDRESS" bash -c "./chaincode/cc-package.sh $CC_NAME $CC_VERSION"

############################################################################################################################################
echo -e "\xE2\x9C\x94 >>> INSTALL CHAINCODE <<<"
for peer_address in ${ORG_PEER_ADDRESSES[@]}; do
    docker exec "$peer_address" bash -c "./chaincode/cc-install.sh $CC_NAME $CC_VERSION"
done

############################################################################################################################################
echo -e "\xE2\x9C\x94 >>> APPROVE CHAINCODE <<<"
for peer_key in ${!ORG_PEER_ADDRESSES[@]}; do
    org_name="${peer_key%_*}"

    orderer_key="${org_name}_0"
    ORG_ORDERER_ADDRESS=${ORG_ORDERER_ADDRESSES[$orderer_key]}

    ORG_PEER_ADDRESS=${ORG_PEER_ADDRESSES[$peer_key]}

    docker exec "$ORG_PEER_ADDRESS" bash -c "./chaincode/cc-approve.sh $ORG_ORDERER_ADDRESS $CHANNEL_ID $CC_NAME $CC_VERSION $CC_SEQ"
done

############################################################################################################################################
echo -e "\xE2\x9C\x94 >>> COMMIT CHAINCODE <<<"
docker exec "$INIT_PEER_ADDRESS" bash -c "./chaincode/cc-commit.sh $INIT_ORDERER_ADDRESS $CHANNEL_ID $CC_NAME $CC_VERSION $CC_SEQ"
