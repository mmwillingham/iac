# All variables: https://github.com/terraform-redhat/terraform-provider-rhcs/blob/main/docs/resources/cluster_rosa_classic.md
# Upgrading: https://github.com/terraform-redhat/terraform-provider-rhcs/blob/main/docs/guides/upgrading-cluster.md
# Machine pools: https://github.com/terraform-redhat/terraform-provider-rhcs/blob/main/docs/guides/machine-pool.md


export TF_VAR_token=<OCM token>
terraform init
terraform plan -var-file="prod.tfvars"
terraform apply -var-file="prod.tfvars" -auto-approve
# For checking cluster logs
rosa logs install -c xxx --watch
rosa create admin -c <clusterid>
or

export TF_VAR_token=<OCM token>
TF_VAR_account_role_prefix=mmw88
TF_VAR_operator_role_prefix=mmw88
terraform init
terraform plan
terraform apply -auto-approve
