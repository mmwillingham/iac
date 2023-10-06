account_role_prefix = "bosez88"
operator_role_prefix = "bosez88"
cluster_name = "bosez88"
admin_username = "bolauder"
admin_password = "Bolauder-password-123"
openshift_version = "4.13"
replicas = 3
cloud_region = "us-east-2"
machine_cidr = "10.0.0.0/16"
multi_az = true
availability_zones = ["${var.cloud_region}a", "${var.cloud_region}b", "${var.cloud_region}c"]
aws_subnet_ids = ["subnet-0a73cb33c1f6c7e2f", "subnet-04930ad373bc82008", "subnet-0b445c03ee780b81d"]
# upgrade_acknowledgements_for = "4.13"
# ocm_environment = "local"
# token = 
# url = "https://api.openshift.com"
# availability_zones = "us-east-2a"
# tags=<aws_resource_tags>
# ec2_metadata_http_tokens=<required_or_optional>
# path
# tags
