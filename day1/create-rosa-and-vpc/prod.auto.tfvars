# REQUIRED VARIABLES

# +----------------------------+
# | prod.auto.tfvars Variables |
# +----------------------------+
cluster_name = "bosez-gdabs"
openshift_version            = "4.14.21"
upgrade_acknowledgements_for = "4.15"
cloud_region                 = "us-east-2"
availability_zones           = ["us-east-2a", "us-east-2b", "us-east-2c"]
#private = true


# +------------------------------+
# | TF Cloud Workspace Variables |
# +------------------------------+
#account_role_prefix = "xxx"
#operator_role_prefix = "xxx"
#admin_username = "xxx"
#admin_password = "xxx"
#token = xxx
