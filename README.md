# minecraft-deploy

Deploy a minecraft server to Azure

## Prerequisites

Deployment was performed on a windows OS with the listed tooling.

- Azure CLI
- VS Code
- Terraform CLI
- Powershell 7
- [Active Azure subscription](https://azure.microsoft.com/en-us/free/)
- [Minecraft server](https://hub.docker.com/r/itzg/minecraft-server) docker image

## Deploy

1. Authenticate to Azure using Azure CLI
1. Supply input variables in `.env` following the [Naming rules and Restrictions](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules)

    These are added as environment variables for the terraform apply
1. At repo root `.\minecraft-deploy` in powershell run `.\bootstrap.ps1`

    Creates a remote backend state container for terraform, initializes and imports resources. The bootstrap only needs to be run once.
1. Run `.\deploy.ps1`

    Deploys minecraft server as single linux container instance. Creates file storage for the docker container volume mount. Deploy.ps1 can be run many times to adjust container settings like cpu and memory allocations.

## Securing your server

- RCON ports are not allocated and are inaccessible
- [server.properties](https://minecraft.fandom.com/wiki/Server.properties) edited to `enforce-whitelist`
- [whitelist.json](https://minecraft.fandom.com/wiki/Whitelist.json) and `ops.json` edited

## Docker Image Updates

On start of the container image `itzg/minecraft-server` latest is pulled by default. To verify the [docker image](https://hub.docker.com/r/itzg/minecraft-server/tags) version look for tags `Latest`, `Linux/amd64`, and a matching digest. See also [Minecraft Server Version](https://www.minecraft.net/en-us/download/server)

## Schedule Container Group

To save money the container group is started and stopped on a schedule. See the `start_trigger` and `stop_trigger` for interval and times. The logic is not complete. The Azure Container Instance start and stop action must be manually configured. Go to the portal and edit the two logic apps to complete the schedule.

There is a potential path to full automation that includes downloading ARM templates and editing them. This is a road that only the desparate travel. In the end I decided to add the action manually.This is also a poor solution since your changes will be destroyed on subsequent runs of `apply`. In the coming months a managed identity option could be used with granted permissions to make an API call from the logic_app to the container group.

<https://wp.sjkp.dk/schedule-start-stop-of-azure-container-instances/>

<https://azapril.dev/2021/04/12/deploying-a-logicapp-with-terraform/>

## Cleanup

Script to clean up logging to recover storage  `./sample_log_delete.ps1`

To remove all azure resources run (RG name found in .env `resource_group`):

`az group delete --name <resource group name> --yes`

Restart world (reseed) - in data storage file share `miner-volume` delete folder defined in server.properties `level-name`

## Other links

<https://www.docker.com/blog/deploying-a-minecraft-docker-server-to-the-cloud/>

<https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs>

<https://github.com/itzg/docker-minecraft-server/>
