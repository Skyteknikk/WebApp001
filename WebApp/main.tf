resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.resource_group_location
  tags = {
       Name = "WebApp1-Prod"
       Environment = "Production"
       }
}

# Terraform State Backend Using Azure Storage
######################################################

resource "azurerm_storage_account" "tfstate" {
  name                     = var.azurerm_storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}

#End Backend block
##########################################################

# Azure Service Plan
##########################################################

resource "azurerm_service_plan" "service_plan" {
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  name  = var.service_plan_name
  os_type             = "Windows"
  sku_name            = var.service_plan_sku 
}

# Web App
############################################################

resource "azurerm_windows_web_app" "webapp" {
  name                = "WebApp${random_id.suffix.hex}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.service_plan.id

  site_config {
    ftps_state            = "FtpsOnly"
    minimum_tls_version   = "1.2"
    always_on             = true
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
  }

  https_only = true
}

resource "random_id" "suffix" {
  byte_length = 4
}

#End App Plan Block
##########################################################


# SQL Server
#############################################################

resource "azurerm_mssql_server" "sql_server" {
  name                         = "sqlserver${random_id.suffix.hex}" #var.sql_server_name
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = var.sql_admin
  administrator_login_password = var.sql_password
}

data "azurerm_mssql_database" "sql_db" {
  name      = var.sql_db_name
  server_id = azurerm_mssql_server.sql_server.id
 # sku_name  = "S0"
 #collation = "SQL_Latin1_General_CP1_CI_AS"
 #max_size_gb = 4
 #transparent_data_encryption_key_vault_key_id = azurerm_key_vault_key.generated.id
}

output "database_id" {
  value = data.azurerm_mssql_database.sql_db.id
}


# Allow Azure services to access SQL
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name                = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address    = "10.0.0.0"
  end_ip_address      = "10.0.0.0"
}



#Use Azure KeyVault to store Secrets
############################################################

resource "azurerm_key_vault" "kv" {
  name                        = var.key_vault_name
  location                    = azurerm_resource_group.main.location
  resource_group_name         = azurerm_resource_group.main.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Create",
      "Delete",
      "Get",
      "Purge",
      "Recover",
      "Update",
      "GetRotationPolicy",
      "SetRotationPolicy"
    ]

    secret_permissions = [
      "Get", "Set", "List", "Delete","Recover","Backup","Restore","Purge"
    ]

    storage_permissions = [
      "Get",
    ]
  }
}

resource "azurerm_key_vault_key" "generated" {
  name         = "generated-certificate"
  key_vault_id = azurerm_key_vault.kv.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  rotation_policy {
    automatic {
      time_before_expiry = "P30D"
    }

    expire_after         = "P90D"
    notify_before_expiry = "P29D"
  }
}

resource "azurerm_key_vault_secret" "sql_password" {
  name         = var.sql_password_secret_name
  value        = var.sql_password
  key_vault_id = azurerm_key_vault.kv.id
}


data "azurerm_client_config" "current" {}

#Virtual network
######################################################

resource "azurerm_virtual_network" "vnet" {
  name                = "secure-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "appgw_subnet" {
  name                 = "appgw-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "appgw_ip" {
  name                = "appgw-ip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_application_gateway" "appgw" {
  name                = "appgateway01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

#### Supported SKU tiers are Standard_v2,WAF_v2.
  sku {
    name     = "WAF_Medium"
    tier     = "WAF_v2" 
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "appgw-ipcfg"
    subnet_id = azurerm_subnet.appgw_subnet.id
  }

  frontend_port {
    name = "frontendPort"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontendIP"
    public_ip_address_id = azurerm_public_ip.appgw_ip.id
  }

  backend_address_pool {
    name = "backendPool"
  }

  backend_http_settings {
    name                  = "httpSettings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20
  }

  http_listener {
    name                           = "listener"
    frontend_ip_configuration_name = "frontendIP"
    frontend_port_name             = "frontendPort"
    protocol                       = "Http"
  }

  url_path_map {
    name                               = "pathMap"
    default_backend_address_pool_name  = "backendPool"
    default_backend_http_settings_name = "httpSettings"

    path_rule {
      name                       = "default-rule"
      paths                      = ["/*"]
      backend_address_pool_name  = "backendPool"
      backend_http_settings_name = "httpSettings"
    }
  }

  request_routing_rule {
    name                       = "rule1"
    rule_type                  = "Basic"
    http_listener_name         = "listener"
    backend_address_pool_name  = "backendPool"
    backend_http_settings_name = "httpSettings"
  }

  waf_configuration {
    enabled          = true
    firewall_mode    = "Prevention"
    rule_set_type    = "OWASP"
    rule_set_version = "3.2"
  }
}

# Creates Log Anaylytics Workspace
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace
resource "azurerm_log_analytics_workspace" "metrix" {
  name                = var.log_analytics_workspace_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}


