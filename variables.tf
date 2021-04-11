variable "location" {
  type        = string
  description = "Region used for all resources"
}

variable "resource_group" {
  type        = string
  description = "Shared management resource group"
}

variable "storage_account" {
  type        = string
  description = "Storage to store the state file"
}