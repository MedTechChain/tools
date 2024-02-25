# dev-tools

## Hyperledger Fabric

We will use docker for Fabric, i.e., will not install any binaries.

1. Make sure you have docker installed and running

2. Run this command 
`curl -sSLO https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/install-fabric.sh && chmod +x install-fabric.sh`. This downloads the `install-fabric.sh` (please do not push the script on the repo).

3. Run `./install-fabric.sh docker`. This downloads the docker images related to Fabric.

## Usage

### Hyperledger Fabric - Tools

Run `tools-cli.sh` to start an interactive terminal within the docker container `fabric-tools`. This container joins the `fabric-tools` network which will be also used by the other nodes. 

The `tools-cmd.sh` script is called by other automation scripts, so the developer can ignore it.

The `scripts` folder is mounted in these containers. These scripts perform commands fabric commands.

### Setup Hyperledger Fabric Infrastructure

1. Run the `infra-up.sh` for setup.
2. Run `infra-down.sh` to clean the environment.

