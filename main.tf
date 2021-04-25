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
  storage_account_name = azurerm_storage_account.state_storage.name
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
    cpu    = "2"
    memory = "2.5"
    environment_variables = {
      "EULA" = "TRUE"
    }

    ports {
      port     = 25565
      protocol = "TCP"
    }

    volume {
      name                 = "minecraft"
      mount_path           = "/data"
      read_only            = false
      share_name           = azurerm_storage_share.volume.name
      storage_account_name = azurerm_storage_account.state_storage.name
      storage_account_key  = azurerm_storage_account.state_storage.primary_access_key
    }
  }
}

resource "azurerm_logic_app_workflow" "start_logic_app" {
  name                = "start_miner_scheduler"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_logic_app_trigger_recurrence" "start_trigger" {
  name         = "start_miner"
  logic_app_id = azurerm_logic_app_workflow.start_logic_app.id
  frequency    = "Day"
  interval     = 1
  time_zone    = "Pacific Standard Time"
  schedule {
      at_these_hours = [ 19 ]
      at_these_minutes = [ 0 ]
  }
}

resource "azurerm_logic_app_workflow" "stop_logic_app" {
  name                = "stop_miner_scheduler"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_logic_app_trigger_recurrence" "stop_trigger" {
  name         = "stop_miner"
  logic_app_id = azurerm_logic_app_workflow.stop_logic_app.id
  frequency    = "Day"
  interval     = 1
  time_zone    = "Pacific Standard Time"
  schedule {
      at_these_hours = [ 1 ]
      at_these_minutes = [ 0 ]
  }
}

# See README to finish container scheduling

output "container_ip" {
    value = azurerm_container_group.miner.ip_address
}

output "container_fqdn" {
    value = azurerm_container_group.miner.fqdn
}