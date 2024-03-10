#!/usr/bin/env bash

# This file configures the entire infrastructure.
# The following files are tightly coupled:
#
# > this file
# > ./configs/crypto/crypto-config.yaml
# > ./configs/configtx/configtx.yaml
# > ./explorer/connection-profile/network.json
#
# Whenever chaning one of them, make sure to change the
# others accordingly.
#

############################################################################################################################################
############################################################## ORGANIZATIONS ###############################################################
############################################################################################################################################

# The values of this array will be used as keys to refer to other configs, defined below
ORG_NAMES=("medtechchain" "medivale" "healpoint" "lifecare")

declare -A ORG_DOMAINS=(
    ["medtechchain"]="medtechchain.nl"
    ["medivale"]="medivale.nl"
    ["healpoint"]="healpoint.nl"
    ["lifecare"]="lifecare.nl"
)
declare -rA ORG_DOMAINS

############################################################################################################################################
############################################################## DOCKER CONFIGS ##############################################################
############################################################################################################################################
GLOBAL_NETWORK="global_network"

declare -A ORG_NETWORKS=(
    ["medtechchain"]="medtechchain"
    ["medivale"]="medivale"
    ["healpoint"]="healpoint"
    ["lifecare"]="lifecare"
)
declare -rA ORG_NETWORKS

ALL_NETWORKS=("$GLOBAL_NETWORK" "${ORG_NETWORKS[@]}")

############################################################################################################################################
############################################################## FABRIC CONFIGS ##############################################################
############################################################################################################################################

############################################################
########################## CHANNEL #########################
############################################################
SYSTEM_CHANNEL="system-channel"
CHANNEL_ID="medtechchain"
APP_CHANNEL_PROFILE_NAME="MedTechChainChannel"
GENESIS_PROFILE_NAME="MedTechChainGenesis"

############################################################
######################### INIT ORG #########################
############################################################
# When setting up the infrastructure, one organization needs to initilize the app channel
# and deploy the chaincode. These variables are used to automate the process.
# Addresses are also used as container names.
INIT_ORG_NAME="medtechchain"
INIT_ORG_DOMAIN="medtechchain.nl"
INIT_PEER_ADDRESS="peer0.medtechchain.nl"
INIT_ORDERER_ADDRESS="orderer0.medtechchain.nl"

############################################################
######################### ORDERERS #########################
############################################################
# Keys are formated as <org_name>_<index>
declare -A ORG_ORDERER_ADDRESSES=(
    ["medtechchain_0"]="orderer0.medtechchain.nl"
    ["medivale_0"]="orderer0.medivale.nl"
    ["healpoint_0"]="orderer0.healpoint.nl"
    ["lifecare_0"]="orderer0.lifecare.nl"
)
declare -rA ORG_ORDERER_ADDRESSES

############################################################
########################## PEERS ###########################
############################################################
# Keys are formated as <org_name>_<index>
declare -A ORG_PEER_ADDRESSES=(
    ["medtechchain_0"]="peer0.medtechchain.nl"
    ["medivale_0"]="peer0.medivale.nl"
    ["healpoint_0"]="peer0.healpoint.nl"
    ["lifecare_0"]="peer0.lifecare.nl"
)
declare -rA ORG_PEER_ADDRESSES

declare -A PEER_HOST_PUBLISHED_PORTS=(
    ["medtechchain_0"]="8051"
    ["medivale_0"]="9051"
    ["healpoint_0"]="10051"
    ["lifecare_0"]="11051"
)
declare -rA PEER_HOST_PUBLISHED_PORTS

########################
### Bootstratp Peers ###
########################
# Keys are formated as <org_name>_<index>
declare -A ORG_BOOTSTRAP_PEER_ADDRESSES=(
    ["medtechchain_0"]="peer0.medtechchain.nl"
    ["medivale_0"]="peer0.medivale.nl"
    ["healpoint_0"]="peer0.healpoint.nl"
    ["lifecare_0"]="peer0.lifecare.nl"
)
declare -rA ORG_BOOTSTRAP_PEER_ADDRESSES

########################
##### Anchor Peers #####
########################
# Keys are formated as <org_name>_<index>
declare -A ORG_ANCHOR_PEER_ADDRESSES=(
    ["medtechchain_0"]="peer0.medtechchain.nl"
    ["medivale_0"]="peer0.medivale.nl"
    ["healpoint_0"]="peer0.healpoint.nl"
    ["lifecare_0"]="peer0.lifecare.nl"
)
declare -rA ORG_ANCHOR_PEER_ADDRESSES

############################################################
############################ MSP ###########################
############################################################
declare -A ORDERER_LOCALMSPIDS=(
    ["medtechchain"]="MedTechChainOrdererMSP"
    ["medivale"]="MediValeOrdererMSP"
    ["healpoint"]="HealPointOrdererMSP"
    ["lifecare"]="LifeCareOrdererMSP"
)
declare -rA ORDERER_LOCALMSPIDS

declare -A PEER_LOCALMSPIDS=(
    ["medtechchain"]="MedTechChainPeerMSP"
    ["medivale"]="MediValePeerMSP"
    ["healpoint"]="HealPointPeerMSP"
    ["lifecare"]="LifeCarePeerMSP"
)
declare -rA PEER_LOCALMSPIDS

declare -A PEER_GROUP_NAMES=(
    ["medtechchain"]="MedTechChainPeer"
    ["medivale"]="MediValePeer"
    ["healpoint"]="HealPointPeer"
    ["lifecare"]="LifeCarePeer"
)
declare -rA PEER_GROUP_NAMES

############################################################################################################################################
############################################################## UTIL FUNCTIONS ##############################################################
############################################################################################################################################
# Exports variables required for running docker containers

# $1 = org. name; $2 = index key
function set_orderer_env_vars {
    org_name="$1"
    index="$2"
    domain=${ORG_DOMAINS[$org_name]}

    source .env
    source ./paths.sh

    orderer_key="${org_name}_$index"

    ORG_NAME=$org_name
    ORDERER_ADDRESS=${ORG_ORDERER_ADDRESSES[$orderer_key]}
    ORDERER_LOCALMSPID=${ORDERER_LOCALMSPIDS[$org_name]}
    GEN_ORDERER_CRYPTOPATH="$GEN_CRYPTO_PATH/ordererOrganizations/$domain/orderers/$ORDERER_ADDRESS"
    ORG_NETWORK=${ORG_NETWORKS[$org_name]}

    export ORG_NAME
    export ORDERER_ADDRESS
    export FABRIC_IMAGE_TAG
    export ORDERER_LOCALMSPID
    export CONFIG_ORDERER_CONFIG_FILE_PATH
    export GEN_ARTIFACTS_GENESIS_BLOCK_FILE_PATH
    export GEN_ORDERER_CRYPTOPATH
    export ORG_NETWORK
    export GLOBAL_NETWORK
}

# $1 = org. name; $2 = index key
function set_peer_env_vars {
    org_name="$1"
    index="$2"
    domain=${ORG_DOMAINS[$org_name]}

    source .env
    source ./paths.sh

    peer_key="${org_name}_$index"

    ORG_NAME=$org_name
    PEER_ADDRESS=${ORG_PEER_ADDRESSES[$peer_key]}
    PEER_LOCALMSPID=${PEER_LOCALMSPIDS[$org_name]}
    GEN_PEER_CRYPTOPATH="$GEN_CRYPTO_PATH/peerOrganizations/$domain/peers/$PEER_ADDRESS"
    GEN_PEER_ADMIN_MSP_PATH="$GEN_CRYPTO_PATH/peerOrganizations/$domain/users/Admin@$domain/msp"
    orderer_key="${org_name}_0" # always connect to the first orderer
    ORDERER_ADDRESS=${ORG_ORDERER_ADDRESSES[$orderer_key]}
    GEN_ORDERER_TLS_CACERT_FILE_PATH="$GEN_CRYPTO_PATH/ordererOrganizations/$domain/orderers/$ORDERER_ADDRESS/msp/tlscacerts/tlsca.$domain-cert.pem"
    ORG_NETWORK=${ORG_NETWORKS[$org_name]}
    PEER_HOST_PORT=${PEER_HOST_PUBLISHED_PORTS[$peer_key]}

    export ORG_NAME
    export PEER_ADDRESS
    export FABRIC_IMAGE_TAG
    export PEER_LOCALMSPID
    export CONFIG_CORE_CONFIG_FILE_PATH
    export GEN_CHAINCODE_SOURCE_PATH
    export GEN_CHAINCODE_PACKAGE_PATH
    export GEN_PEER_CRYPTOPATH
    export GEN_PEER_ADMIN_MSP_PATH
    export GEN_ORDERER_TLS_CACERT_FILE_PATH
    export GEN_ARTIFACTS_CHANNEL_PATH
    export UTIL_SCRIPTS_PEER_PATH
    export ORG_NETWORK
    export GLOBAL_NETWORK
    export PEER_HOST_PORT
}
