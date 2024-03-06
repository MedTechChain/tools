#!/bin/bash

FABRIC_DIR="$(
    cd -- "$(dirname "$0")" >/dev/null 2>&1
    pwd -P
)"
cd "$FABRIC_DIR"

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

./gradlew installDist

if [ ! -d "./build/install" ]; then
    echo "Error: Chaincode build failed"
    exit 3
fi

cd "$FABRIC_DIR"

CC_NAME=medtechchain
CC_VERSION=0.0.1

rm -rf "./.generated/cc-src/$CC_NAME"
cp -r "$CC_SRC_PATH/build/install/$CC_NAME" "./.generated/cc-src/"

docker exec "peer2.medtechchain.nl" bash -c "./cc-package.sh $CC_NAME $CC_VERSION"

for domain in "medtechchain.nl" "medivale.nl" "healpoint.nl" "lifecare.nl"; do
    for peer in "peer2"; do # not enough resources to intall on all peers
        docker exec "$peer.$domain" bash -c "./cc-install.sh $peer $domain $CC_NAME $CC_VERSION"
    done
done

for domain in "medtechchain.nl" "medivale.nl" "healpoint.nl" "lifecare.nl"; do
    for peer in "peer2"; do # not enough resources to intall on all peers
        docker exec "$peer.$domain" bash -c "./cc-approve.sh $peer $domain $CC_NAME $CC_VERSION 1"
    done
done

docker exec "peer2.medtechchain.nl" bash -c "./cc-commit.sh $CC_NAME $CC_VERSION 1"