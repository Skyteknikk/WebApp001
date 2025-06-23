# WebApp01Atea
Atea task on deploying a webapp with Sql server with terraform
Here is a clean and organized version of the Terraform project to deploy a WebApp and SQL database on Azure, with GitHub Actions CI/CD:

Project Structure

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


Settings → Secrets and variables → Actions → New repository secret

Add:

ARM_CLIENT_ID

ARM_CLIENT_SECRET

ARM_SUBSCRIPTION_ID

ARM_TENANT_ID

Then replace hardcoded auth values in terraform.tfvars with:

hcl
Copier
Modifier
client_id        = var.client_id
client_secret    = var.client_secret
subscription_id  = var.subscription_id
tenant_id        = var.tenant_id
In deploy.yml, inject secrets as environment variables if needed.

✅ Done
Now, whenever you push to the main branch, GitHub Actions will:

Run Terraform

Deploy the WebApp and SQL DB to Azure

Print the WebApp URL in the GitHub Actions log

Would you like a downloadable ZIP or a GitHub template repo version?




