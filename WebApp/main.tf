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
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

#End Backend block
##########################################################

# App Service Plan
##########################################################

resource "azurerm_app_service_plan" "app_service_plan" {
  name                = var.app_service_plan_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  sku {
    tier = "Standard"
    size = var.app_service_plan_sku
  }

  kind = "Linux"
  reserved = true
}

# Web App
############################################################
resource "azurerm_linux_web_app" "webapp" {
  name                = "LinuxWebApp${random_id.suffix.hex}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  service_plan_id     = azurerm_app_service_plan.app_service_plan.id

  site_config {
    linux_fx_version = "DOTNETCORE|6.0"
    ftps_state       = "FtpsOnly"
    minimum_tls_version = "1.2"
    always_on = true
  }
  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
   }
  }

  identity {
    type = "SystemAssigned"
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


resource "azurerm_sql_server" "sql_server" {
  name                         = "sqlserver${random_id.suffix.hex}" #var.sql_server_name
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = var.sql_admin
  administrator_login_password = var.sql_password

  identity {
    type = "SystemAssigned"
  }
}

# SQL Database
###############################################################
resource "azurerm_sql_database" "sql_db" {
  name           = var.sql_db_name
  server_id      = azurerm_sql_server.sql_server.id
  sku_name       = "S0"
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  max_size_gb    = 4

  server_name         = azurerm_sql_server.sql_server.name
  requested_service_objective_name = "Basic"  # Cost-effective
  
  tags = {
    db = "prod-db"
  }

  identity {
    type         = "SystemAssigned"
  }

  transparent_data_encryption_key_vault_key_id = azurerm_key_vault_key.kv.id

  # prevent the possibility of accidental data loss
  lifecycle {
    prevent_destroy = true
  }
}

# Allow Azure services to access SQL
resource "azurerm_sql_firewall_rule" "allow_azure_services" {
  name                = "AllowAzureServices"
  resource_group_name = azurerm_resource_group.main.name
  server_name         = azurerm_sql_server.sql_server.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}



#Use Azure KeyVault to store Secrets
############################################################

resource "azurerm_key_vault" "kv" {
  name                        = var.key_vault_name
  location                    = var.location
  resource_group_name         = azurerm_resource_group.main.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"

  soft_delete_enabled         = true
  purge_protection_enabled    = true

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = ["get", "set", "list", "delete"]
  }
}

resource "azurerm_key_vault_secret" "sql_password" {
  name         = var.sql_password_secret_name
  value        = var.sql_password
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_key" "kv" {
  name         = "sql-tde-key"
  key_vault_id = azurerm_key_vault.kv.id
  key_type     = "RSA"
  key_size     = 2048
}

data "azurerm_client_config" "current" {}

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

  sku {
    name     = "WAF_Medium"
    tier     = "WAF"
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
    name                           = "pathMap"
    default_backend_address_pool_name = "backendPool"
    default_backend_http_settings_name = "httpSettings"
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


