variable "token" {
  type      = string
  sensitive = true
}

variable "url" {
  type        = string
  description = "Provide OCM environment by setting a value to url"
  default     = "https://api.openshift.com"
}

variable "operator_role_prefix" {
  type = string
}

variable "account_role_prefix" {
  type = string
}


variable "rosa_openshift_version" {
  type        = string
  default     = "4.15.0"
  description = "Desired version of OpenShift for the cluster, for example '4.15.0'. If version is greater than the currently running version, an upgrade will be scheduled."
}

variable "account_role_policies" {
  description = "account role policies details for account roles creation"
  type = object({
    sts_installer_permission_policy             = string
    sts_support_permission_policy               = string
    sts_instance_worker_permission_policy       = string
    sts_instance_controlplane_permission_policy = string
  })
  default = null
}

variable "operator_role_policies" {
  description = "operator role policies details for operator roles creation"
  type = object({
    openshift_cloud_credential_operator_cloud_credential_operator_iam_ro_creds_policy = string
    openshift_cloud_network_config_controller_cloud_credentials_policy                = string
    openshift_cluster_csi_drivers_ebs_cloud_credentials_policy                        = string
    openshift_image_registry_installer_cloud_credentials_policy                       = string
    openshift_ingress_operator_cloud_credentials_policy                               = string
    openshift_machine_api_aws_cloud_credentials_policy                                = string
  })
  default = null
}

# ROSA Cluster info
variable "cluster_name" {
  default     = null
  type        = string
  description = "Provide the name of your ROSA cluster."
}

variable "additional_tags" {
  default = {
    Terraform   = "true"
  }
  description = "Additional AWS resource tags"
  type        = map(string)
}

variable "path" {
  description = "(Optional) The arn path for the account/operator roles as well as their policies."
  type        = string
  default     = null
}

variable "machine_type" {
  description = "The AWS instance type used for your default worker pool."
  type        = string
  default     = "m5.xlarge"
}

variable "worker_node_replicas" {
  default     = 2
  description = "Number of worker nodes to provision. Single zone clusters need at least 2 nodes, multizone clusters need at least 3 nodes"
  type        = number
}

variable "autoscaling_enabled" {
  description = "Enables autoscaling. This variable requires you to set a maximum and minimum replicas range using the 'max_replicas' and 'min_replicas' variables. If the autoscaling_enabled is 'true', you cannot configure the worker_node_replicas."
  type        = string
  default     = "false"
}

#VPC Info
variable "vpc_cidr_block" {
  type        = string
  description = "The value of the IP address block for machines or cluster nodes for the VPC."
  default     = "10.0.0.0/16"
}

#AWS Info
variable "aws_region" {
  type    = string
  default = "us-east-1"
}
