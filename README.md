# App Services Basic Architecture

 ![Architectural](https://github.com/Skyteknikk/WebApp001/blob/main/Solution.jpg)
This repository contains terraform code to deploy a stand alone Web app Azure App Services basic architecture.

# Reference for the Architecture

[Basic SetApp](https://learn.microsoft.com/en-us/azure/architecture/web-apps/app-service/architectures/basic-web-app)
[Enterprise Deployment] (https://learn.microsoft.com/en-us/azure/architecture/web-apps/app-service-environment/architectures/ase-standard-deployment)

## Deploy

The following are prerequisites.

## Prerequisites

1. Azure Subscription  [Azure Account](https://azure.microsoft.com/free/)
1. Visual Studio Code [Azure CLI installed](https://learn.microsoft.com/cli/azure/install-azure-cli)
1. GitHub [az Bicep tools installed](https://learn.microsoft.com/azure/azure-resource-manager/bicep/install)

Used in this solution are the following infrastructure.

### Deploy the infrastructure

The following steps are required to deploy the infrastructure from the command line.

1. In your command-line tool where you have the Azure CLI and Bicep installed, navigate to the root directory of this repository (AppServicesRI)

1. Login and set subscription if it is needed

```bash
  az login 
  az account set --subscription xxxxx
```

1. Update the infra-as-code/parameters file

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "baseName": {
      "value": ""
    },
    "sqlAdministratorLogin": {
      "value": ""
    },
    "sqlAdministratorLoginPassword": {
      "value": ""
    }
  }
}
```

Note: Take into account that sql database enforce [password complexity](https://learn.microsoft.com/sql/relational-databases/security/password-policy?view=sql-server-ver16#password-complexity)

1. Run the following command to create a resource group and deploy the infrastructure. Make sure:

   - The BASE_NAME contains only lowercase letters and is between 6 and 12 characters. All resources will be named given this basename.
   - You choose a valid resource group name

```bash
   LOCATION=westus3
   BASE_NAME=<base-resource-name>
   RESOURCE_GROUP=<resource-group-name>

   az group create --location $LOCATION --resource-group $RESOURCE_GROUP

   az deployment group create --template-file ./infra-as-code/bicep/main.bicep \
     --resource-group $RESOURCE_GROUP \
     --parameters @./infra-as-code/bicep/parameters.json \
     --parameters baseName=$BASE_NAME
```

### Publish the web app

Deploy zip file from [App Service Sample Workload](https://github.com/Azure-Samples/app-service-sample-workload)

```bash
APPSERVICE_NAME=app-$BASE_NAME
az webapp deploy --resource-group $RESOURCE_GROUP --name $APPSERVICE_NAME --type zip --src-url https://raw.githubusercontent.com/Azure-Samples/app-service-sample-workload/main/website/SimpleWebApp.zip
```

### Validate the web app

Retrieve the web application URL and open it in your default web browser.

```bash
APPSERVICE_URL=https://$APPSERVICE_NAME.azurewebsites.net
echo $APPSERVICE_URL
```

## Optional Step: Service Connector

This implementation is using a classic connection string to access the database, the connection string is stored in an App Service setting called "AZURE_SQL_CONNECTIONSTRING". You can use [Service Connector](https://learn.microsoft.com/azure/service-connector/overview) to configure the connection. Service Connector makes it easy and simple to establish and maintain connections between services. It reduces manual configuration and maintenance difficulties. You can use Service Connector either from Azure Portal, Azure CLI or even from Visual Studio to create connections.

You must open [Azure Cloud Shell on bash mode](https://learn.microsoft.com/azure/cloud-shell/quickstart) to execute these CLI commands. The commands need to connect the database and only azure services are allowed in the current configuration.

```bash
   # Set variables on Azure Cloud Shell
   LOCATION=westus3
   BASE_NAME=<base-resource-name>
   RESOURCE_GROUP=<resource-group-name>
   APPSERVICE_NAME=app-$BASE_NAME
   RESOURCEID_DATABASE=$(az deployment group show -g $RESOURCE_GROUP -n databaseDeploy --query properties.outputs.databaseResourceId.value -o tsv)
   RESOURCEID_WEBAPP=$(az deployment group show -g $RESOURCE_GROUP -n webappDeploy --query properties.outputs.appServiceResourceId.value -o tsv)
   USER_IDENTITY_WEBAPP_CLIENTID=$(az deployment group show -g $RESOURCE_GROUP -n webappDeploy --query properties.outputs.appServiceIdentity.value -o tsv)
   USER_IDENTITY_WEBAPP_SUBSCRIPTION=$(az deployment group show -g $RESOURCE_GROUP -n webappDeploy --query properties.outputs.appServiceIdentitySubscriptionId.value -o tsv)
   
   # Delete current app service conection string, you could verify that the key was deleted from the Azure portal
   az webapp config appsettings delete --name $APPSERVICE_NAME --resource-group $RESOURCE_GROUP --setting-names AZURE_SQL_CONNECTIONSTRING

   # Install the service connector CLI extension
   az extension add --name serviceconnector-passwordless --upgrade

   # Invoke the service connection command
   az webapp connection create sql --connection sql_adventureconn --source-id $RESOURCEID_WEBAPP --target-id $RESOURCEID_DATABASE --client-type dotnet --user-identity client-id=$USER_IDENTITY_WEBAPP_CLIENTID subs-id=$USER_IDENTITY_WEBAPP_SUBSCRIPTION
   # The AZURE_SQL_CONNECTIONSTRING was created again but the connection string now includes "Authentication=ActiveDirectoryManagedIdentity"
   
```

## Clean Up

After you have finished exploring the AppService reference implementation, it is recommended that you delete Azure resources to prevent undesired costs from accruing.

```bash
az group delete --name $RESOURCE_GROUP -y
```


# Architecture

Diagram that shows a basic App Service architecture.

The diagram shows an Azure App Service connecting directly to an Azure SQL Database. The diagram also shows Azure App Insights and Azure Monitor.

Figure 1: Basic Azure App Service architecture

Download a Visio file of this architecture.

# Workflow

A user issues an HTTPS request to the App Service's default domain on azurewebsites.net. This domain automatically points to your App Service's built-in public IP. The TLS connection is established from the client directly to app service. The certificate is managed completely by Azure.
Easy Auth, a feature of Azure App Service, ensures that the user accessing the site is authenticated with Microsoft Entra ID.
Your application code deployed to App Service handles the request. For example, that code might connect to an Azure SQL Database instance, using a connection string configured in the App Service configured as an app setting.
The information about original request to App Service and the call to Azure SQL Database are logged in Application Insights.
Components
Microsoft Entra ID is a cloud-based identity and access management service. It provides a single identity control plane to manage permissions and roles for users accessing your web application. It integrates with App Service and simplifies authentication and authorization for web apps.
App Service is a fully managed platform for building, deploying, and scaling web applications.
Azure Monitor is a monitoring service that collects, analyzes, and acts on telemetry data across your deployment.
Azure SQL Database is a managed relational database service for relational data.
Considerations
These considerations implement the pillars of the Azure Well-Architected Framework, which is a set of guiding tenets that can be used to improve the quality of a workload. For more information, see Microsoft Azure Well-Architected Framework.

The components listed in this architecture link to Azure Well-Architected service guides. Service guides detail recommendations and considerations for specific services. This section extends that guidance by highlighting key Azure Well-Architected Framework recommendations and considerations that apply to this architecture. For more information, see Microsoft Azure Well-Architected Framework.

This basic architecture isn't intended for production deployments. The architecture favors simplicity and cost efficiency over functionality to allow you to evaluate and learn Azure App Service. The following sections outline some deficiencies of this basic architecture, along with recommendations and considerations.

# Security features

It's important to start this process in the PoC phase. As you move toward production, you want the ability to automatically deploy your infrastructure.
Use different ARM Templates and integrate them with Azure DevOps services. This setup lets you create different environments. For example, you can replicate production-like scenarios or load testing environments only when needed and save on cost.
For more information, see the DevOps section in Azure Well-Architected Framework.

# Reliability features

Reliability ensures your application can meet the commitments you make to your customers. For more information, see Design review checklist for Reliability.

Because this architecture isn't designed for production deployments, the following outlines some of the critical reliability features that are omitted in this architecture:

The App Service Plan is configured for the Standard tier, which doesn't have Azure availability zone support. The App Service becomes unavailable in the event of any issue with the instance, the rack, or the datacenter hosting the instance.
The Azure SQL Database is configured for the Basic tier, which doesn't support zone-redundancy. This means that data isn't replicated across Azure availability zones, risking loss of committed data in the event of an outage.
Deployments to this architecture might result in downtime with application deployments, as most deployment techniques require all running instances to be restarted. Users may experience 503 errors during this process. This deployment downtime is addressed in the baseline architecture through deployment slots. Careful application design, schema management, and application configuration handling are necessary to support concurrent slot deployment. Use this POC to design and validate your slot-based production deployment approach.
Autoscaling isn't enabled in this basic architecture. To prevent reliability issues due to lack of available compute resources, you'd need to overprovision to always run with enough compute to handle max concurrent capacity.
See how to overcome these reliability concerns in the reliability section in the Baseline highly available zone-redundant web application.

If this workload will eventually require a multi-region active-active or active-passive architecture, see the following resource:

Multi-region App Service app approaches for disaster recovery for guidance on deploying your App Service-hosted workload across multiple regions.
Security
Security provides assurances against deliberate attacks and the abuse of your valuable data and systems. For more information, see Design review checklist for Security.

Because this architecture isn’t designed for production deployments, the following outlines some of the critical security features that were omitted in this architecture, along with other reliability recommendations and considerations:

This basic architecture doesn't implement network privacy. The data and management planes for the resources, such as the Azure App Service and Azure SQL Server, are reachable over the public internet. Omitting private networking significantly increases the attack surface of your architecture. To see how implementing private networking ensures the following security features, see the networking section of the Baseline highly available zone-redundant web application:

A single secure entry point for client traffic
Network traffic is filtered both at the packet level and at the DDoS level.
Data exfiltration is minimized by keeping traffic in Azure by using Private Link
Network resources are logically grouped and isolated from each other through network segmentation.
This basic architecture doesn't include a deployment of the Azure Web Application Firewall. The web application isn't protected against common exploits and vulnerabilities. See the baseline implementation to see how the Web Application Firewall can be implemented with Azure Application Gateway in an Azure App Services architecture.

This basic architecture stores secrets such as the Azure SQL Server connection string in App Settings. While app settings are encrypted, when moving to production, consider storing secrets in Azure Key Vault for increased governance. An even better solution is to use managed identity for authentication and not have secrets stored in the connection string.

Leaving remote debugging and Kudu endpoints enabled while in development or the proof of concept phase is fine. When you move to production, you should disable unnecessary control plane, deployment, or remote access.

Leaving local authentication methods for FTP and SCM site deployments enabled is fine while in the development or proof of concept phase. When you move to production, you should disable local authentication to those endpoints.

You don't need to enable Microsoft Defender for App Service in the proof of concept phase. When moving to production, you should enable Defender for App Service to generate security recommendations you should implement to increase your security posture and to detect multiple threats to your App Service.

Azure App Service includes an SSL endpoint on a subdomain of azurewebsites.net at no extra cost. HTTP requests are redirected to the HTTPS endpoint by default. For production deployments, you'll typically use a custom domain associated with application gateway or API management in front of your App Service deployment.

Use the integrated authentication mechanism for App Service ("EasyAuth"). EasyAuth simplifies the process of integrating identity providers into your web app. It handles authentication outside your web app, so you don't have to make significant code changes.

Use managed identity for workload identities. Managed identity eliminates the need for developers to manage authentication credentials. The basic architecture authenticates to SQL Server via password in a connection string. Consider using managed identity to authenticate to Azure SQL Server.

For some other security considerations, see Secure an app in Azure App Service.

# Cost Optimization features

Cost Optimization is about looking at ways to reduce unnecessary expenses and improve operational efficiencies. For more information, see Design review checklist for Cost Optimization.

This architecture optimizes for cost through the many trade-offs against the other pillars of the Well-Architected Framework specifically to align with the learning and proof-of-concept goals of this architecture. The cost savings compared to a more production-ready architecture, such as the Baseline highly available zone-redundant web application, mainly result from the following choices.

Single App Service instance, with no autoscaling enabled
Standard pricing tier for Azure App Service
No custom TLS certificate or static IP
No web application firewall (WAF)
No dedicated storage account for application deployment
Basic pricing tier for Azure SQL Database, with no backup retention policies
No Microsoft Defender for Cloud components
No network traffic egress control through a firewall
No private endpoints
Minimal logs and log retention period in Log Analytics
To view the estimated cost of this architecture, see the Pricing calculator estimate using this architecture's components. The cost of this architecture can usually be further reduced by using an Azure Dev/Test subscription, which would be an ideal subscription type for proof of concepts like this.

# Operational Excellence

Operational Excellence covers the operations processes that deploy an application and keep it running in production. For more information, see Design review checklist for Operational Excellence.

The following sections provide guidance around configuration, monitoring, and deployment of your App Service application.

App configurations
Because the basic architecture isn't intended for production, it uses App Service configuration to store configuration values and secrets. Storing secrets in App Service configuration is fine for the PoC phase. You aren't using real secrets and don't require secrets governance that production workloads require.

The following are configuration recommendations and considerations:

Start by using App Service configuration to store configuration values and connection strings in proof of concept deployments. App settings and connection strings are encrypted and decrypted just before being injected into your app when it starts.
When you move into production phase, store your secrets in Azure Key Vault. The use of Azure Key Vault improves the governance of secrets in two ways:
Externalizing your storage of secrets to Azure Key Vault allows you to centralize your storage of secrets. You have one place to manage secrets.
Using Azure Key Vault, you're able to log every interaction with secrets, including every time a secret is accessed.
When you move into production, you can maintain your use of both Azure Key Vault and App Service configuration by using Key Vault references.
Containers
The basic architecture can be used to deploy supported code directly to Windows or Linux instances. Alternatively, App Service is also a container hosting platform to run your containerized web application. App Service offers various built-in containers. If you're using custom or multi-container apps to further fine-tune your runtime environment or to support a code language not natively supported, you'll need to introduce a container registry.

# Control plane

During the POC phase, get comfortable with Azure App Service's control plane as exposed through the Kudu service. This service exposes common deployment APIs, such as ZIP deployments, exposes raw logs and environment variables.

If using containers, be sure to understand Kudu's ability to Open an SSH session to a container to support advanced debugging capabilities.

Diagnostics and monitoring
During the proof of concept phase, it's important to get an understanding of what logs and metrics are available to be captured. The following are recommendations and considerations for monitoring in the proof of concept phase:

Enable diagnostics logging for all items log sources. Configuring the use of all diagnostic settings helps you understand what logs and metrics are provided for you out of the box and any gaps you'll need to close using a logging framework in your application code. When you move to production, you should eliminate log sources that aren't adding value and are adding noise and cost to your workload's log sink.
Configure logging to use Azure Log Analytics. Azure Log Analytics provides you with a scalable platform to centralize logging that is easy to query.
Use Application Insights or another Application Performance Management (APM) tool to emit telemetry and logs to monitor application performance.

# Deployment

It's important to start this process in the PoC phase. As you move toward production, you want the ability to automatically deploy your infrastructure.
Use different ARM Templates and integrate them with Azure DevOps services. This setup lets you create different environments. For example, you can replicate production-like scenarios or load testing environments only when needed and save on cost.
For more information, see the DevOps section in Azure Well-Architected Framework.

# Performance Efficiency
Performance Efficiency is the ability of your workload to meet the demands placed on it by users in an efficient manner. For more information, see Design review checklist for Performance Efficiency.

Because this architecture isn't designed for production deployments, the following outlines some of the critical performance efficiency features that were omitted in this architecture, along with other recommendations and considerations.

An outcome of your proof of concept should be SKU selection that you estimate is suitable for your workload. Your workload should be designed to efficiently meet demand through horizontal scaling by adjusting the number of compute instances deployed in the App Service Plan. Do not design the system to depend on changing the compute SKU to align with demand.

The App Service in this basic architecture doesn't have automatic scaling implemented. The service doesn't dynamically scale out or in to efficiently keep aligned with demand.
The Standard tier does support auto scale settings to allow you to configure rule-based autoscaling. Part of your POC process should be to arrive at efficient autoscaling settings based on your application code's resource needs and expected usage characteristics.
For production deployments, consider Premium tiers that support automatic autoscaling where the platform automatically handles scaling decisions.
Follow the guidance to scale up individual databases with no application downtime if you need a higher service tier or performance level for SQL Database.



# WebApp01Atea

Atea task on deploying a webapp with Sql server with terraform
Here is a clean and organized version of the Terraform project to deploy a WebApp and SQL database on Azure, with GitHub Actions CI/CD:

# Project Structure

```
webapp-sql-terraform/
│
├── main.tf                # Main infrastructure definitions
├── variables.tf           # All input variables
├── terraform.tfvars       # Actual values for variables
├── outputs.tf             # Outputs like WebApp URL
│
└── .github/
    └── workflows/
        └── deploy.yml     # GitHub Actions CI/CD workflow
```


We set the secrets in Github via Settings → Secrets and variables → Actions → New repository secret

Add:

```
ARM_CLIENT_ID  ..... client_id  

ARM_CLIENT_SECRET ..... client_secret 

ARM_SUBSCRIPTION_ID ...... subscription_id

ARM_TENANT_ID ..... tenant_id 

```

In deploy.yml, inject secrets as environment variables if needed.

## Automatic Deployement logic

Whenever you push to the main branch, GitHub Actions will:

Run Terraform

Deploy the WebApp and SQL DB to Azure

Print the WebApp URL in the GitHub Actions log





