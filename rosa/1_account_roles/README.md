# Export Variables
export TF_VAR_token=<see ~/ocm_token.txt>
export TF_operator_role_prefix=bolauder
export TF_VAR_url=https://api.openshift.com

# Export Optional variables
export TF_VAR_account_role_prefix=blsez
export TF_VAR_openshift_version=4.13
#export TF_VAR_tags=<aws_resource_tags> (Optional) 

# Execute
terraform init
terraform plan -out account-roles.tfplan # Optional
terraform apply <"account-roles.tfplan"> 

## Verification
rosa list account-roles
