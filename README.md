# iac
https://github.com/terraform-redhat/terraform-provider-rhcs/blob/main/examples/create_rosa_sts_cluster/classic_sts/cluster/README.md

https://excalidraw.com/#json=LSeUV72meWCj8uAd5iJfv,cKAWQw8wKRIAM-pn9e8isA
https://developer.hashicorp.com/terraform/tutorials/automation/github-actions
https://registry.terraform.io/browse/providers
clis needed
rosa
ocm
terraform client:
	sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
	sudo yum install terraform

## Create an AWS account
### demo.redhat.com > labs > AWS ILT
### https://github.com/mmwillingham/acm/tree/main/create_rosa_cluster

## Create basic AWS resources
```bash
cd aws-basic
terraform init
terraform plan # optional
terraform apply -auto-approve
```

## Cleanup
```bash
terraform plan # optional
terraform destroy -auto-approve
```

# Next steps
## combine account roles and cluster creation (depends on?)
## create vpc and subnets first, then use them in cluster creation
## get token from Vault
## add outputs
### https://github.com/hashicorp/learn-terraform-outputs
## terraform cloud - store state there
## kickoff terraform from something else
## variables
