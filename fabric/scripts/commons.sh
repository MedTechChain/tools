#!/bin/bash

################ COMMONS: DOMAINS & CONFIGS ################
ORG_NAMES=("medtechchain" "medivale" "healpoint" "lifecare")

CHANNEL_ID="medtechchain"
APP_CHANNEL_PROFILE_NAME="MedTechChainChannel"
GENESIS_PROFILE_NAME="MedTechChainGenesis"

GLOBAL_NETWORK="global_network"
DOCKER_NETWORKS=("$GLOBAL_NETWORK" "${ORG_NAMES[@]}")


declare -A ORG_DOMAINS

for NAME in ${ORG_NAMES[@]}; do
    ORG_DOMAINS[$NAME]="$NAME.nl" 
done

NUM_OF_ORDERERS=1

declare -A ORG_ORDERER_IDS

for NAME in ${ORG_NAMES[@]}; do
    for i in $(seq 0 $((NUM_OF_ORDERERS-1))); do
        ORG_ORDERER_IDS[$NAME,$i]="orderer$i."${ORG_DOMAINS[$NAME]}
    done
done

NUM_OF_PEERS=1

declare -A ORG_PEER_IDS

for NAME in ${ORG_NAMES[@]}; do
    for i in $(seq 0 $((NUM_OF_PEERS-1))); do
        ORG_PEER_IDS[$NAME,$i]="peer$i."${ORG_DOMAINS[$NAME]}
    done
done

declare -A CHAINCODE_HOST_PORTS
PORT=8052

for ORG_PEER_ID in ${ORG_PEER_IDS[@]}; do
    CHAINCODE_HOST_PORTS[$ORG_PEER_ID]="$PORT"
    ((PORT += 1000)) 
done


NUM_OF_ANCHOR_PEERS=1

declare -A ORG_ANCHOR_PEER_IDS

for NAME in ${ORG_NAMES[@]}; do
    for i in $(seq 0 $((NUM_OF_PEERS-1))); do
        ORG_ANCHOR_PEER_IDS[$NAME,$i]="peer$i."${ORG_DOMAINS[$NAME]}
    done
done

INIT_ORG_NAME=${ORG_NAMES[0]}
INIT_ORG_DOMAIN=${ORG_DOMAINS[$INIT_ORG_NAME]}
INIT_PEER_ID=${ORG_PEER_IDS[$INIT_ORG_NAME,0]}
INIT_ORDERER_ID=${ORG_ORDERER_IDS[$INIT_ORG_NAME,0]}

declare -A ORG_ORDERER_LOCALMSPIDS
declare -A ORG_PEER_LOCALMSPIDS

ORG_ORDERER_LOCALMSPIDS[${ORG_NAMES[0]}]="MedTechChainOrdererMSP"
ORG_PEER_LOCALMSPIDS[${ORG_NAMES[0]}]="MedTechChainPeerMSP"

ORG_ORDERER_LOCALMSPIDS[${ORG_NAMES[1]}]="MediValeOrdererMSP"
ORG_PEER_LOCALMSPIDS[${ORG_NAMES[1]}]="MediValePeerMSP"

ORG_ORDERER_LOCALMSPIDS[${ORG_NAMES[2]}]="HealPointOrdererMSP"
ORG_PEER_LOCALMSPIDS[${ORG_NAMES[2]}]="HealPointPeerMSP"

ORG_ORDERER_LOCALMSPIDS[${ORG_NAMES[3]}]="LifeCareOrdererMSP"
ORG_PEER_LOCALMSPIDS[${ORG_NAMES[3]}]="LifeCarePeerMSP"

declare -A ORG_PEER_GROUP_NAMES

ORG_PEER_GROUP_NAMES[${ORG_NAMES[0]}]="MedTechChainPeer"
ORG_PEER_GROUP_NAMES[${ORG_NAMES[1]}]="MediValePeer"
ORG_PEER_GROUP_NAMES[${ORG_NAMES[2]}]="HealPointPeer"
ORG_PEER_GROUP_NAMES[${ORG_NAMES[3]}]="LifeCarePeer"

