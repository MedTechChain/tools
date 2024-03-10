#!/usr/bin/env bash


# This file defines paths that are frequently used, relative
# to the position of the current script. You must update
# this file whenever you move any file in the repo.
#

FABRIC_DIR_PATH="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 && pwd -P)" # Changes when the script is moved

DEV_TOOLS_DIR_PATH="$FABRIC_DIR_PATH/.."
CHAINCODE_REPO_DIR_PATH="$DEV_TOOLS_DIR_PATH/../chaincode" # Path to chaincode repo


# The followings MUST be defined relative to FABRIC_DIR_PATH,
# and MUST be relative paths since they will be used inside
# docker containers which need to work with paths relative to
# the `fabric` directory.
CONFIG_CRYPTO_FILE_PATH="./configs/crypto/crypto-config.yaml"
CONFIG_CONFIGTX_PATH="./configs/configtx"
CONFIG_COMPOSE_TEMPLATES_PATH="./configs/docker"
CONFIG_ORDERER_CONFIG_FILE_PATH="./configs/node/orderer.yaml"
CONFIG_CORE_CONFIG_FILE_PATH="./configs/node/core.yaml"

UTIL_SCRIPTS_PATH="./scripts"
UTIL_SCRIPTS_PEER_PATH="$UTIL_SCRIPTS_PATH/peer"
UTIL_SCRIPTS_TOOLS_PATH="$UTIL_SCRIPTS_PATH/tools"

EXPLORER_PATH="./explorer"

GEN_PATH="./.generated"

GEN_CRYPTO_PATH="$GEN_PATH/crypto"

GEN_ARTIFACTS_PATH="$GEN_PATH/artifacts"
GEN_ARTIFACTS_GENESIS_BLOCK_FILE_PATH="$GEN_ARTIFACTS_PATH/genesis/genesis.block"
GEN_ARTIFACTS_CHANNEL_PATH="$GEN_ARTIFACTS_PATH/channel"

GEN_CHAINCODE_PATH="$GEN_PATH/chaincode"
GEN_CHAINCODE_SOURCE_PATH="$GEN_CHAINCODE_PATH/src"
GEN_CHAINCODE_PACKAGE_PATH="$GEN_CHAINCODE_PATH/pkg"
