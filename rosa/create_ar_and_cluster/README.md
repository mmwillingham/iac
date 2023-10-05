export TF_VAR_token=<OCM token>
terraform init
terraform plan -var-file="demo.tfvars"
terraform apply -var-file="demo.tfvars" -auto-approve

or
export TF_VAR_token=<OCM token>
TF_VAR_account_role_prefix=mmw88
TF_VAR_operator_role_prefix=mmw88
terraform init
terraform plan
terraform apply -auto-approve
