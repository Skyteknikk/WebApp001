provider "azurerm" {
  features {}
  client_id       = var.client_id
  client_secret   = var.client_secret
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.34.0"
    }
  }

 backend "azurerm" {
    resource_group_name   = azurerm_resource_group.main.name
    storage_account_name  = "webapp01tfstatestorage"
    container_name        = "webapp01tfstate"
    key                   = "webapp-sql-app.terraform.tfstate"
  }
}