#############################################
# Global Configuration
#############################################
resource_group_name           = "win-webapp001-rg"
resource_group_location       = "westeurope"

#############################################
# Terraform Backend Storage
#############################################
azurerm_storage_account_name  = "tfstatestorage000000"  # must be globally unique

#############################################
# App Service Plan
#############################################
service_plan_name         = "webapp-serviceplan"
service_plan_sku          = "S1"

#############################################
# SQL Server & Database
#############################################
sql_admin                     = "sqladminuser"
sql_password                  = "OurStrongSecurePassword123!"  # Replace with a secure, strong password
sql_db_name                   = "webapp-db"

#############################################
# Azure Key Vault Configuration
#############################################
key_vault_name                = "webappsecurekv"
sql_password_secret_name      = "sqladmin-password"

#############################################
# Tags / Metadata
#############################################
environment                   = "Production"
application_name              = "WebApp1"
#############################################
log_analytics_workspace_name = "WebAppLogSpace001"
