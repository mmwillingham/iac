# Not working yet


https://developer.hashicorp.com/vault/tutorials/hcp-vault-secrets-get-started/hcp-vault-secrets-create-secret
https://developer.hashicorp.com/vault/tutorials/hcp-vault-secrets-get-started/hcp-vault-secrets-install-cli
https://developer.hashicorp.com/vault/tutorials/hcp-vault-secrets-get-started/hcp-vault-secrets-retrieve-secret
https://developer.hashicorp.com/vault/tutorials/hcp-vault-secrets-get-started/hcp-vault-secrets-terraform

# Create application
Login to https://portal.cloud.hashicorp.com/
    Vault Secrets > Apps > Create new application > test1
    Add new secret > ocm_token

# Download cli
sudo yum update -y
sudo yum install -y yum-utils
curl -fsSL https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo | sudo tee /etc/yum.repos.d/hashicorp.repo
sudo yum update
sudo yum install vlt -y
vlt
vlt login
vlt config init
    Select test1
vlt secrets
    Select ocm_token

# Retrieve secret
vlt secrets get username
vlt secrets get --plaintext username

# Use terraform
https://registry.terraform.io/providers/hashicorp/hcp/latest/docs
https://developer.hashicorp.com/vault/tutorials/hcp-vault-secrets-get-started/hcp-vault-secrets-terraform

Login to https://portal.cloud.hashicorp.com/
Access control (IAM) > Service Principals > Create Service Principal
mmwtest > admin
Select mmwtest > Create service principal key
Save values in bitwarden

Export values to shell
export HCP_CLIENT_ID=
export HCP_CLIENT_SECRET=
printenv | grep HCP_

tee example.tf <<EOF
terraform {
  required_providers {
    hcp = {
      source = "hashicorp/hcp"
      version = "0.63.0"
    }
  }
}

provider "hcp" {
  # Configuration options
}

data "hcp_vault_secrets_app" "example" {
  app_name = "test1"
}

output "secrets" {
  #value = data.hcp_vault_secrets_app.example.secrets
  value = data.hcp_vault_secrets_app.test1.secrets
  sensitive = true
}
EOF

terraform init
terraform apply -auto-approve
terraform output secrets
