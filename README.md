# tools

## Install Hyperledger Fabric

Installing any Fabric binary is not required since everything is set up to use Docker.

1. Have Docker installed
2. Run: `curl -sSLO https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/install-fabric.sh && chmod +x install-fabric.sh && ./install-fabric.sh docker`.

## Prerequisites

- **`OS`**: Linux (tested for Ubuntu, Arch, MacOS)
- **`Containerization`**: Docker Desktop

## Project structure

The developer should normally use only the scripts in the `fabric` directory.

The `fabric/scripts` contains utilitary scripts, used by the scripts from `fabric` directory. The `fabric/scripts/peer` and `fabric/scripts/tools` will be mounted inside peer/tool containers to facilitate automation.

## Developer scripts

* Run `fabric/tools-cli.sh` to start an interactive terminal within a `fabric/tools` container.
* Run `fabric/infra-start.sh [--light]` for setting up the infrastrcture. Light mode runs fewer hospitals. After setting up the infrastructure, the developer is supposed to provide the generated crypto material to the rest of applications (copy in the repsective repos with util scripts). Note: Once setting an light infra, the developer has to completely clean the infra and recopy the crypto material when regenerated.
* Run `fabric/infra-stop.sh` stops the infra without deleting generated crypto material and state. Use `fabric/infra-start.sh [--light]` to start it.
* Run `fabric/infra-clean.sh` completely purges the entire infrastructure, deleting state and generated crypto material.
* Run the `cc-deploy.sh` to deploy the chaincode. Make sure to provide the path to the `chaincode` repo folder or have in at the same level as the `tools` repo folder. When you deploy a new version, make sure to increase the version and sequence number in the `fabric/.env` file. These can be reset by recreating the infrasturcture. As a current limitation, after some point, the infrastrcture has to be reseted after some chaincode deployments since the messages for updaiting it exceed the maximum size (did not have time to investigate into it).

Please refer to the `Known problems` section in case of problems.


## Explorer

Accessible at `localhost:9000`. Sometimes requires refresh before being properly displayed. Username and password: `admin`.


Please refer to the `Known problems` section in case of problems.

### Application Development - Port Mapping
* **Peer ports**:
    * `peer0.medtechchain.nl` - 8051
    * `peer0.medivale.nl` - 9051
    * `peer0.healpoint.nl` - 10051
    * `peer0.lifecare.nl` - 11051

Please refer to the `configs` folder for specific configurations.

### Known problems

1. `Permission problems`: Docker Service runs in root mode, while Docker Desktop runs in rootless mode. What this means, for Docker Service, any file generated from within the container, and made available on host through volumes belong to root, whereas for Docker Desktop, they belong to the current user. The following scripts are designed to work with Docker Desktop. To overcome this, when running Docker Service, change the owner of all generated files before/after you run scripts:
```
sudo chown -R ${USER}:${USER} <PATH_TO_.GENERATED>
```
Another alternative is to run the script as root.

Finally, you could circumvent this using remapping:

### Enabling User Namespace Remapping in Docker

Here's how you can set up user namespace remapping:
* **Configure Docker Daemon**: You need to edit the Docker daemon configuration file, typically located at `/etc/docker/daemon.json`, to enable user namespace remapping.
    
    jsonCopy code
    
    `{   "userns-remap": "default" }`
    
    The `"default"` setting automatically creates and uses a new user and group (`dockremap`) on your host system. Docker will assign a range of UIDs and GIDs from the host to be used for the user namespaces.
    
* **Restart Docker Service**: After changing the configuration, you'll need to restart the Docker service to apply the changes. You can do this by running:
    
    bashCopy code
    
    `sudo systemctl restart docker`
    
* **Verify the Configuration**: Once Docker restarts, any new container you run will have user namespace remapping enabled. Files created by `root` inside the container will be owned by the `dockremap` user on the host.
    
* **Custom Mapping**: If you want a specific user on your host to own the files, you can create a custom mapping instead of using `"default"`. First, ensure the user and corresponding group exist on your host, then specify them in the Docker daemon configuration:
    
    jsonCopy code
    
    `{   "userns-remap": "yourusername" }`
    
    Replace `yourusername` with the actual username on your host system. Docker will need to be able to find or create a subordinate UID and GID range entry for this user in `/etc/subuid` and `/etc/subgid`.
    
* **Adjust Permissions and Ownership**: Ensure that the directory on the host that you're using for the bind mount has the appropriate permissions so that the remapped user can read, write, and execute as necessary.

2. `Explorer not available`: Sometimes Explorer does not work, though the container is running. This is because the image is badly designed, making the container to remain alive even when the server itself dies within the container. To fix this, restart the container and constantly check logs:
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

4. `Running out of memory`: Increase Swap size. 16 GB Ram barely suffices for one chaincode deployment with only one hospital, together with the other applications.
