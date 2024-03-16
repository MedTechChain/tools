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

## Folder strucutre

All other repositories should be placed in a common root. This is required since there is the need to place the crypto material in the other repositories before build.

### Hyperledger Fabric - Tools

Run `fabric/tools-cli.sh` to start an interactive terminal within the docker container `fabric-tools`.

The `fabric/tools-cmd.sh` script is called by other automation scripts, so the developer can ignore it.

The `fabric/scripts` folder is mounted in these containers. These scripts perform fabric commands.

### Setup Hyperledger Fabric Infrastructure

1. Run the `infra/infra-start.sh [--light]` for setup. Light mode runs fewer hospitals
2. Run the `cc-deploy.sh` to deploy the chaincode. Make sure to provide the path to the `chaincode` repo folder or have in at the same level as the `dev-tools` repo folder. When you deploy a new version, make sure to update the version and sequence number in the `fabric/.env` file. These can be reset by recreating the infrasturcture.

### Application Development - Port Mapping
* **Peer ports**:
    * `peer0.medtechchain.nl` - 8051
    * `peer0.medivale.nl` - 9051
    * `peer0.healpoint.nl` - 10051
    * `peer0.lifecare.nl` - 11051

### Deploying a new Chaincode version

Before any deployiment using `cc-deploy.sh`, make sure to set the vairables in the `.env` to new unique values (version and sequence).

### Clean Hyperledger Fabric Infrastructure
1. Start/stop infra using the `infra-start.sh`/`infra-stop.sh`
1. Run `infra-clean.sh` for a full clean

### Project scripts

The util scripts in the `dev-tools` folder perform operations accross the project repos and start all services:
* `./all-run.sh [--light] [<SMTP_PASSWORD>]`
* `./all-stop.sh [--clean]` (the flag cleans all volumes)
* `./ums-be-run.sh [--light] [<SMTP_PASSWORD>]`
* `./ums-be-stop.sh [--clean]` (the flag cleans all volumes)

### Known problems

1. `Permission problems`: Docker Service runs in root mode, while Docker Desktop runs in rootless mode. What this means, for Docker Service, any file generated from within the container, and made available on host through volumes belong to root, whereas for Docker Desktop, they belong to the current user. The following scripts are designed to work with Docker Desktop. To overcome this, when running Docker Service, change the owner of all generated files before/after you run scripts:
```
sudo chown -R ${USER}:${USER} <PATH_TO_.GENERATED>
```
Another alternative is to run the script as root.

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
