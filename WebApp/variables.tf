
# Global Configuration
###############################################################
variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "webapp-secure-rg"
}

variable "resource_group_location" {
  description = "Azure region for resource deployment"
  type        = string
  default     = "eastus"
}

# Terraform State Backend Using Azure Storage
#############################################################
variable "azurerm_storage_account_name" {
  description = "Name of the Azure Storage Account for Terraform state"
  type        = string
  default     = "tfstatestorage000000"  # must be globally unique
}

# App Service Plan
###############################################################
variable "app_service_plan_name" {
  description = "Name of the App Service Plan"
  type        = string
  default     = "webapp-serviceplan"
}

variable "app_service_plan_sku" {
  description = "SKU size for the App Service Plan"
  type        = string
  default     = "S1"
}

# SQL Server & Database
############################################################
variable "sql_admin" {
  description = "Administrator username for the SQL Server"
  type        = string
  default     = "sqladminuser"
}

variable "sql_password" {
  description = "Administrator password for the SQL Server"
  type        = string
  sensitive   = true
}

variable "sql_db_name" {
  description = "Name of the SQL Database"
  type        = string
  default     = "webapp-db"
}

# Key Vault Configuration
###############################################################
variable "key_vault_name" {
  description = "Name of the Azure Key Vault"
  type        = string
  default     = "webappsecurekv"
}

variable "sql_password_secret_name" {
  description = "Name of the Key Vault secret for the SQL password"
  type        = string
  default     = "sqladmin-password"
}

#Web Application firewall
###############################################################



#######################

# Optional Tags
variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "Production"
}

variable "application_name" {
  description = "Name of the application"
  type        = string
  default     = "WebApp1"
}
