terraform {
  required_version = ">= 0.13"

  backend "azurerm" {
    key = "tfstate"
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=2.46.0"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group
  location = var.location
}

# Generate random text for a unique storage account name
resource "random_string" "dns_label" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.rg.name
    }

    length  = 8
    special = false
    number  = true
    upper   = false
}

resource "azurerm_storage_account" "state_storage" {
  name                      = var.storage_account
  resource_group_name       = azurerm_resource_group.rg.name
  location                  = azurerm_resource_group.rg.location
  account_tier              = "Standard"
  account_kind              = "StorageV2"
  account_replication_type  = "LRS"
  allow_blob_public_access  = false
  enable_https_traffic_only = true
}

resource "azurerm_storage_share" "volume" {
  name                 = "miner-volume"
  storage_account_name = "${azurerm_storage_account.state_storage.name}"
  quota                = 50
}

resource "azurerm_container_group" "miner" {
  name                = "minecart"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_address_type     = "public"
  dns_name_label      = "minecart-${random_string.dns_label.id}"
  os_type             = "Linux"

  container {
    name   = "mc"
    image  = "itzg/minecraft-server"
    cpu    = "0.5"
    memory = "2"
    environment_variables = {
      "EULA" = "TRUE"
    }

    ports {
      port     = 25565
      protocol = "TCP"
    }

    volume {
      name       = "minecraft"
      mount_path = "/data"
      read_only  = false
      share_name = azurerm_storage_share.volume.name
      storage_account_name = azurerm_storage_account.state_storage.name
      storage_account_key  = azurerm_storage_account.state_storage.primary_access_key
    }
  }
}

output "container_ip" {
    value = azurerm_container_group.miner.ip_address
}