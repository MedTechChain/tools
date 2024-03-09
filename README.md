# dev-tools

## Hyperledger Fabric

We will use docker for Fabric, i.e., will not install any binaries.

1. Make sure you have docker installed and running

2. Run this command 
`curl -sSLO https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/install-fabric.sh && chmod +x install-fabric.sh`. This downloads the `install-fabric.sh` (please do not push the script on the repo).

3. Run `./install-fabric.sh docker`. This downloads the docker images related to Fabric.

## Usage

Designed for:
* `OS`: Ubuntu
* `Containerization`: Docker Desktop

### Hyperledger Fabric - Tools

Run `tools-cli.sh` to start an interactive terminal within the docker container `fabric-tools`. This container joins the `fabric-tools` network which will be also used by the other nodes. 

The `tools-cmd.sh` script is called by other automation scripts, so the developer can ignore it.

The `scripts` folder is mounted in these containers. These scripts perform commands fabric commands.

### Setup Hyperledger Fabric Infrastructure

1. Run the `infra-up.sh` for setup.
2. Run the `cc-deploy.sh` to deploy the chaincode. Make sure to provide the path to the `chaincode` repo folder or have in at the same level as the `dev-tools` repo folder. When you deploy a new version, it is better to recreate the infrastructure.

### Application Development - Port Mapping
* **Chaincode ports**:
    * `peer0.medtechchain.nl` - localhost:10052
    * `peer0.medivale.nl` - localhost:9052
    * `peer0.healpoint.nl` - localhost:8052
    * `peer0.lifecare.nl` - localhost:11052
* **Peer ports**:
    * `peer0.medtechchain.nl` - localhost:10051
    * `peer0.medivale.nl` - localhost:9051
    * `peer0.healpoint.nl` - localhost:8051
    * `peer0.lifecare.nl` - localhost:11051

### Chaincode Development - Chaincode as a Service
TODO: Coming soon

### Clean Hyperledger Fabric Infrastructure
1. Run `infra-down.sh` to clean the environment.

### Known problems

1. `Permission problems`: Docker Service runs in root mode, while Docker Desktop runs in rootless mode. What this means, for Docker Service, any file generated from within the container, and made available on host through volumes belong to root, whereas for Docker Desktop, they belong to the current user. The following scripts are designed to work with Docker Desktop. To overcome this, when running Docker Service, change the owner of all generated files before/after you run scripts:
```
sudo chown -R ${USER}:${USER} <PATH_TO_.GENERATED>
```

2. `Explorer not available`: Sometimes Explorer does not work, though the container is running. This is because the image is badly design, and we cannot change it, making the container to remain alive even when the server itself dies within the container. To fix this, restart the container:
```
docker restart explorer.medtechchain.nl
```

3. `Chaincode containers`: Due to a Docker bug, the Chaincode containers sometimes do not join the network and detecting this cannot be automated. If the chaincode containers do not work, simply remove the containers. A new container should be created, hoping that this time it will join the network. Repeat the following process until the container works properly:

- identify the id of the problematic container
```
docker ps -a
```
- stop and remove that container
```
docker stop <ID>
docker rm <ID>
```
