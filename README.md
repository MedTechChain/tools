# dev-tools

## Hyperledger Fabric

We will use docker for Fabric, i.e., will not install any binaries.

1. Make sure you have docker installed and running

2. Run this command 
`curl -sSLO https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/install-fabric.sh && chmod +x install-fabric.sh`. This downloads the `install-fabric.sh` (please do not push the script on the repo).

3. Run `./install-fabric.sh docker`. This downloads the docker images related to Fabric.

## Usage

### Hyperledger Fabric - Tools

Run `tools-cli.sh [IMAGE_VERSION]` to start an interactive terminal within the docker container `fabric-tools`. This container joins the `healthblocks` network which will be also used by the other nodes.

### Setup Hyperledger Fabric Infrastructure

1. Run the `generate.sh` script while using the `tools-cli.sh`.

2. Exit the interactive terminal.

3. Run the `infra-setup.sh [IMAGE_VERSION]`.

