##  Overview

This project provisions an Azure Web App and SQL Database using Terraform. The solution emphasizes cost-efficiency, security, and enterprise-grade best practices.
Since its a standalone deployment of a WebApp using a App Azure Service, the solution does not implement or address scalability or high availability in respect of the solution architecture.
The solution may also be low on Performance Efficiency if it cannot be scaled

# Solution Architecture Diagram

 ![Architectural](https://github.com/Skyteknikk/WebApp001/blob/main/Solution.jpg)
This repository contains terraform code to deploy a stand alone Web app Azure App Services basic architecture.

## ☁️ Solution Components Deployed

- ✅ Azure Virtual Network With Subnets
- ✅ Azure Subnets Fixed with NSG 
- ✅ Azure Resource Group
- ✅ Azure App Service Plan (Basic Tier)
- ✅ Azure App Service (Web App)
- ✅ Azure SQL Server
- ✅ Azure SQL Database
- ✅ Azure Application Gateway + WAF
- ✅ Azure Key Vault
- ✅ Azure Log Analytic Workspace

- ⚙️  Azure Application Gateway or Azure Front Door will achieve the same thing to secure ingress in this deployment we go with Application Gateway
-  Azure Key Vault is always recommended for secrets management either used by the application or database.

# Reference for the Architecture

[Basic SetApp](https://learn.microsoft.com/en-us/azure/architecture/web-apps/app-service/architectures/basic-web-app)
[Enterprise Deployment] (https://learn.microsoft.com/en-us/azure/architecture/web-apps/app-service-environment/architectures/ase-standard-deployment)

[Best Practices] (https://learn.microsoft.com/en-us/azure/well-architected/service-guides/app-service-web-apps)


# App Logic Workflow

> - A user issues an HTTPS request to the App Service's default domain on azurewebsites.net. This domain automatically points to your App Service's built-in public IP. 
> - The TLS connection is established from the client directly to app service. The certificate is managed completely by Azure.
> - Easy Auth, a feature of Azure App Service, ensures that the user accessing the site is authenticated with Microsoft Entra ID.
> - connect to an Azure SQL Database instance, using a connection string configured in the App Service configured as an app setting.
> - The information about original request to App Service and the call to Azure SQL Database are logged in Application Insights.

## Project Structure


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

# Identity Consideration

> - Us Microsoft Entra to provide a single identity control plane to manage permissions and roles for users accessing your web application. 
> - Aiming to easily integrates with App Service and simplifies authentication and authorization for web apps.

# Reliability Considerations

> - The App Service Plan is configured for the Standard tier, which doesn't have Azure availability zone support. 
> - The App Service becomes unavailable in the event of any issue with the instance, the rack, or the datacenter hosting the instance.
> - The Azure SQL Database is configured for the Basic tier, which doesn't support zone-redundancy. This means that data isn't replicated across Azure availability zones, risking loss of committed data in the event of an outage.
> - Deployments to this architecture might result in downtime with application deployments, as most deployment techniques require all running instances to be restarted. Users may experience 503 errors during this process. 
> - This deployment downtime is addressed in the baseline architecture through deployment slots. Careful application design, schema management, and application configuration handling are necessary to support concurrent slot deployment. 
> - Autoscaling isn't enabled in this basic architecture. Multi-region App Service app approaches for disaster recovery 

# Security Considerations

> - A single secure entry point for client traffic
> - Network traffic is filtered both at the packet level and at the DDoS level.
> - Data exfiltration is minimized by keeping traffic in Azure by using Private Link
> - Network resources are logically grouped and isolated from each other through network segmentation by subnets with own NSG.
> - Deployment of the Azure Web Application Firewall to protected against common exploits and vulnerabilities. 
> - Secrets are to be stored in Azure Key Vault for increased governance. 
> - Utilizing managed identity for authentication and not have secrets stored in the connection string is recommended
> - Disable local authentication to endpoints.
> - Enable Defender for App Service to generate security recommendations.
> - Azure App Service includes an SSL endpoint on a subdomain of azurewebsites.net at no extra cost. 
> - HTTP requests are redirected to the HTTPS endpoint by default and using a custom domain associated with application gateway
> - Using managed identity to authenticate to Azure SQL Server.

# Cost Optimization Considerations


The solution architecture is optimizes for cost with a few trade offs against 7 pillars of the Well-Architected Framework such as scalabity and high availability
The cost savings mainly effects the Baseline for highly available zone-redundant web application.

> - Single App Service instance, with no autoscaling enabled
> - Standard pricing tier for Azure App Service
> - No custom TLS certificate or static IP
> - Basic pricing tier for Azure SQL Database, with no backup retention policies
> - No private endpoints
> - Minimal logs and log retention period in Log Analytics

The estimated cost of this architecture can be computed using  the Pricing calculator estimate using this architecture's components.

# Operational Excellence Considerations

App configurations

App settings and connection strings are encrypted and decrypted 
Secrets are to be stored in Azure Key Vault to improve the governance of secrets.
Azure Key Vault enables the centralization of storing of secrets. 
Using Azure Key Vault enables able the logging of every interaction with secrets, including every time a secret is accessed.


# Performance Efficiency Considerations

> - Support for horizontal scaling by adjusting the number of compute instances deployed in the App Service Plan.
> - The Standard tier does support auto scale settings to allow the configuration of rule-based autoscaling. 
> - Considering production deployments, Premium tiers is recommended as it supports automatic autoscaling where the platform automatically handles scaling decisions.


## Security Considerations

- Web App traffic is secured via allowing only **HTTPS** connections
- SQL Server credentials are stored securely (use Azure Key Vault or GitHub Secrets)
- Security enhancement Suggestions: Private endpoints for SQL, Private DNS Zones for SQL and KeyVault.
- Infrastructure deployed with **Terraform** for auditability and version control

---

## Cost Optimization

- **Basic SKU** used for App Service Plan and SQL Database
- Minimum viable services deployed — scalable if needed
- Use of **tags** for cost tracking and governance

---

##  Deployment Instructions
   # Option 1
   
> - Prerequisites:
> - Terraform CLI installed
> - Azure CLI authenticated (`az login`)
> - Azure subscription assigned

# Clone your GitHub repository
git clone https://github.com/<your-org>/<your-repo>.git
cd terraform/

# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan

# Apply the infrastructure
terraform apply

# Option 2

> - Visual Studio Code
> - Github Repository
> - Azure subscription assigned

git clone https://github.com/<your-org>/<your-repo>.git

# Option 2

> - Github Repo
> - Github Action


## Azure Client Credentials

We set the secrets in Github via Settings → Secrets and variables → Actions → New repository secret

Add:

```
ARM_CLIENT_ID  ..... client_id  

ARM_CLIENT_SECRET ..... client_secret 

ARM_SUBSCRIPTION_ID ...... subscription_id

ARM_TENANT_ID ..... tenant_id 

```

In deploy.yml, inject secrets as environment variables if needed.



