```
### Good info: https://github.com/terraform-redhat/terraform-provider-rhcs/blob/806c3e5b80ee41e60d1db99e10e0511e5d55a85e/README.md?plain=1#L45
### All variables: https://github.com/terraform-redhat/terraform-provider-rhcs/blob/main/docs/resources/cluster_rosa_classic.md
### Upgrading: https://github.com/terraform-redhat/terraform-provider-rhcs/blob/main/docs/guides/upgrading-cluster.md
### Machine pools: https://github.com/terraform-redhat/terraform-provider-rhcs/blob/main/docs/guides/machine-pool.md

### Vault: https://developer.hashicorp.com/vault/tutorials/hcp-vault-secrets-get-started/hcp-vault-secrets-install-cli

export TF_VAR_token=<OCM token>
terraform init
terraform validate
terraform plan -var-file="prod.tfvars"
terraform apply -var-file="prod.tfvars" -auto-approve
# For checking cluster logs
rosa list clusters
rosa logs install -c <clustername> --watch
$ No need to create cluster-admin if you created admin_username in the tf code
# rosa create admin -c <clustername>
or

export TF_VAR_token=<OCM token>
TF_VAR_account_role_prefix=mmw88
TF_VAR_operator_role_prefix=mmw88
terraform init
terraform plan
terraform apply -auto-approve
```
