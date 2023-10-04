# Create or adjust .tfvars file.
## Note: The OCM environment value should be one of those: production, staging, integration, local.

# Export Variable for token
## [OCM offline token](https://console.redhat.com/openshift/token)
export TF_VAR_token=<see ~/ocm_token.txt>

# Execute
terraform init
terraform plan -var-file="demo.tfvars" # Optional
terraform apply -var-file="demo.tfvars"


# Verification
rosa list account-roles

# Cleanup (don't do this if you're creating a cluster in the next step)
terraform destroy
