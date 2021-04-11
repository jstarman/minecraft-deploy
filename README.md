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

## Cleanup

To remove all azure resources run (RG name found in .env `resource_group`):

`az group delete --name <resource group name> --yes`

## Other links

<https://www.docker.com/blog/deploying-a-minecraft-docker-server-to-the-cloud/>

<https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs>

<https://github.com/itzg/docker-minecraft-server/>
