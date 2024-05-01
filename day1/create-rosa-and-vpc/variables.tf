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

variable "openshift_version" {
  type        = string
  description = "Desired version of OpenShift for the cluster, for example '4.1.0'. If the version is later than the currently running version, an upgrade is scheduled."
}

variable "aws_account_id" {
  type        = string
  default     = null
  description = "The AWS account identifier where all resources are created during the installation of the ROSA cluster. If no information is provided, the data is retrieved from the currently connected account."
}

variable "aws_account_arn" {
  type        = string
  default     = null
  description = "The ARN of the AWS account where all resources are created during the installation of the ROSA cluster. If no information is provided, the data is retrieved from the currently connected account."
}

#variable "oidc_config_id" {
#  type        = string
#  description = "The unique identifier associated with users authenticated through OpenID Connect (OIDC) within the ROSA cluster."
#}

variable "installer_role_arn" {
  type        = string
  default     = null
  description = "The Amazon Resource Name (ARN) associated with the AWS IAM role used by the ROSA installer."
}

variable "support_role_arn" {
  type        = string
  default     = null
  description = "The Amazon Resource Name (ARN) associated with the AWS IAM role used by Red Hat SREs to enable access to the cluster account in order to provide support."
}

variable "controlplane_role_arn" {
  type        = string
  default     = null
  description = "The Amazon Resource Name (ARN) associated with the AWS IAM role that is used by the cluster's control plane instances."
}

variable "worker_role_arn" {
  type        = string
  default     = null
  description = "The Amazon Resource Name (ARN) associated with the AWS IAM role that is used by the cluster's compute instances."
}

variable "base_dns_domain" {
  type        = string
  default     = null
  description = "Base DNS domain name previously reserved and matching the hosted zone name of the private Route 53 hosted zone associated with intended shared VPC, e.g., '1vo8.p1.openshiftapps.com'."
}

variable "aws_subnet_ids" {
  type        = list(string)
  default     = []
  description = "The Subnet IDs to use when installing the cluster. Leave blank for installer provisioned subnet IDs."
}

variable "aws_additional_infra_security_group_ids" {
  type        = list(string)
  default     = null
  description = "The additional security group IDs to be added to the infra worker nodes."
}

variable "aws_additional_control_plane_security_group_ids" {
  type        = list(string)
  default     = null
  description = "The additional security group IDs to be added to the control plane nodes."
}

variable "kms_key_arn" {
  type        = string
  default     = null
  description = "The key ARN is the Amazon Resource Name (ARN) of a CMK. It is a unique, fully qualified identifier for the CMK. A key ARN includes the AWS account, region, and the key ID."
}

variable "aws_private_link" {
  type        = bool
  default     = null
  description = "Provides private connectivity between VPCs, AWS services, and on-premises networks, without exposing traffic to the public internet. (default: false)"
}

variable "private" {
  type        = bool
  default     = null
  description = "Restrict master API endpoint and application routes to direct, private connectivity. (default: false)"
}

variable "machine_cidr" {
  type        = string
  default     = null
  description = "Block of IP addresses used by OpenShift while installing the cluster, for example \"10.0.0.0/16\"."
}

variable "service_cidr" {
  type        = string
  default     = null
  description = "Block of IP addresses for services, for example \"172.30.0.0/16\"."
}

variable "pod_cidr" {
  type        = string
  default     = null
  description = "Block of IP addresses from which pod IP addresses are allocated, for example \"10.128.0.0/14\"."
}

variable "host_prefix" {
  type        = number
  default     = null
  description = "Subnet prefix length to assign to each individual node. For example, if host prefix is set to \"23\", then each node is assigned a /23 subnet out of the given CIDR."
}

variable "ec2_metadata_http_tokens" {
  type        = string
  default     = null
  description = "Should cluster nodes use both v1 and v2 endpoints or just v2 endpoint of EC2 Instance Metadata Service (IMDS). Available since OpenShift 4.11.0."
}

##############################################################
# Proxy variables
##############################################################

variable "http_proxy" {
  type        = string
  default     = null
  description = "A proxy URL to use for creating HTTP connections outside the cluster. The URL scheme must be http."
}

variable "https_proxy" {
  type        = string
  default     = null
  description = "A proxy URL to use for creating HTTPS connections outside the cluster."
}

variable "no_proxy" {
  type        = string
  default     = null
  description = "A comma-separated list of destination domain names, domains, IP addresses or other network CIDRs to exclude proxying."
}

variable "additional_trust_bundle" {
  type        = string
  default     = null
  description = "A string containing a PEM-encoded X.509 certificate bundle that is added to the nodes' trusted certificate store."
}

variable "admin_credentials_username" {
  type        = string
  default     = null
  description = "Admin username that is created with the cluster. auto generated username - \"cluster-admin\""
}

variable "admin_credentials_password" {
  type        = string
  default     = null
  description = "Admin password that is created with the cluster. The password must contain at least 14 characters (ASCII-standard) without whitespaces including uppercase letters, lowercase letters, and numbers or symbols."
}

variable "private_hosted_zone_id" {
  type        = string
  default     = null
  description = "ID assigned by AWS to private Route 53 hosted zone associated with intended shared VPC, e.g., 'Z05646003S02O1ENCDCSN'."
}

variable "private_hosted_zone_role_arn" {
  type        = string
  default     = null
  description = "AWS IAM role ARN with a policy attached, granting permissions necessary to create and manage Route 53 DNS records in private Route 53 hosted zone associated with intended shared VPC."
}

##############################################################
# Optional properties and tags
##############################################################

variable "properties" {
  description = "User defined properties."
  type        = map(string)
  default     = null
}

variable "tags" {
  description = "Apply user defined tags to all cluster resources created in AWS. After the creation of the cluster is completed, it is not possible to update this attribute."
  type        = map(string)
  default     = null
}

##############################################################
# Optional ROSA Cluster Installation flags
##############################################################

variable "wait_for_create_complete" {
  type        = bool
  default     = true
  description = "Wait until the cluster is either in a ready state or in an error state. The waiter has a timeout of 60 minutes. (default: true)"
}

variable "disable_workload_monitoring" {
  type        = bool
  default     = null
  description = "Enables you to monitor your own projects in isolation from Red Hat Site Reliability Engineer (SRE) platform metrics."
}

variable "disable_scp_checks" {
  type        = bool
  default     = null
  description = "Indicates if cloud permission checks are disabled when attempting installation of the cluster."
}

variable "etcd_encryption" {
  type        = bool
  default     = null
  description = "Add etcd encryption. By default etcd data is encrypted at rest. This option configures etcd encryption on top of existing storage encryption."
}

variable "fips" {
  type        = bool
  default     = null
  description = "Create cluster that uses FIPS Validated / Modules in Process cryptographic libraries."
}

variable "disable_waiting_in_destroy" {
  type        = bool
  default     = null
  description = "Disable addressing cluster state in the destroy resource. Default value is false, and so a `destroy` waits for the cluster to be deleted."
}

variable "destroy_timeout" {
  type        = number
  default     = null
  description = "Maximum duration in minutes to allow for destroying resources. (Default: 60 minutes)"
}

variable "upgrade_acknowledgements_for" {
  type        = bool
  default     = null
  description = "Indicates acknowledgement of agreements required to upgrade the cluster version between minor versions (e.g. a value of \"4.12\" indicates acknowledgement of any agreements required to upgrade to OpenShift 4.12.z from 4.11 or before)."
}


##############################################################
# Default Machine Pool Variables
# These attributes are specifically applies for the default Machine Pool and becomes irrelevant once the resource is created.
# Any modifications to the default Machine Pool should be made through the Terraform imported Machine Pool resource.
##############################################################

variable "multi_az" {
  type        = bool
  default     = null
  description = "Specifies whether the deployment of the cluster should extend across multiple availability zones. (default: false)"
}

variable "replicas" {
  type        = number
  default     = null
  description = "Number of worker nodes to provision. This attribute is applicable solely when autoscaling is disabled. Single zone clusters need at least 2 nodes, multizone clusters need at least 3 nodes. Hosted clusters require that the number of worker nodes be a multiple of the number of private subnets. (default: 2)"
}

variable "min_replicas" {
  type        = number
  default     = null
  description = "Minimum number of compute nodes. This attribute is applicable solely when autoscaling is enabled. (default: 2)"
}

variable "max_replicas" {
  type        = number
  default     = null
  description = "Maximum number of compute nodes. This attribute is applicable solely when autoscaling is enabled. (default: 2)"
}

variable "compute_machine_type" {
  type        = string
  default     = null
  description = "Identifies the instance type used by the default worker machine pool e.g. `m5.xlarge`. Use the `rhcs_machine_types` data source to find the possible values."
}

variable "worker_disk_size" {
  type        = number
  default     = null
  description = "Default worker machine pool root disk size with a **unit suffix** like GiB or TiB, e.g. 200GiB."
}

variable "default_mp_labels" {
  type        = map(string)
  default     = null
  description = "Labels for the worker machine pool. This list overwrites any modifications made to node labels on an ongoing basis."
}

variable "aws_availability_zones" {
  type        = list(string)
  default     = []
  description = "The AWS availability zones where instances of the default worker machine pool are deployed. Leave blank for the installer to pick availability zones."
}

variable "aws_additional_compute_security_group_ids" {
  type        = list(string)
  default     = null
  description = "The additional security group IDs to be added to the default worker machine pool."
}

##############################################################
# Autoscaler resource variables
##############################################################

variable "cluster_autoscaler_enabled" {
  type        = bool
  default     = false
  description = "Enable autoscaler for this cluster."
}

variable "autoscaler_balance_similar_node_groups" {
  type        = bool
  default     = null
  description = "Automatically identifies node groups with the same instance type and the same set of labels and tries to keep the respective sizes of those node groups balanced."
}

variable "autoscaler_skip_nodes_with_local_storage" {
  type        = bool
  default     = null
  description = "If true, cluster autoscaler never deletes nodes with pods with local storage, e.g. EmptyDir or HostPath. Default is true."
}

variable "autoscaler_log_verbosity" {
  type        = number
  default     = null
  description = "Sets the autoscaler log level. Default value is 1, level 4 is recommended for DEBUGGING and level 6 enables almost everything."
}

variable "autoscaler_max_pod_grace_period" {
  type        = number
  default     = null
  description = "Gives pods graceful termination time before scaling down."
}

variable "autoscaler_pod_priority_threshold" {
  type        = number
  default     = null
  description = "To allow users to schedule 'best-effort' pods, which does not trigger cluster autoscaler actions, but only run when there are spare resources available."
}

variable "autoscaler_ignore_daemonsets_utilization" {
  type        = bool
  default     = null
  description = "Should cluster-autoscaler ignore DaemonSet pods when calculating resource utilization for scaling down. Default is false."
}

variable "autoscaler_max_node_provision_time" {
  type        = string
  default     = null
  description = "Maximum time cluster-autoscaler waits for node to be provisioned."
}

variable "autoscaler_balancing_ignored_labels" {
  type        = list(string)
  default     = null
  description = "This option specifies labels that cluster autoscaler ignores when considering node group similarity. For example, if you have nodes with 'topology.ebs.csi.aws.com/zone' label, you can add name of this label here to prevent cluster autoscaler from splitting nodes into different node groups based on its value."
}

variable "autoscaler_max_nodes_total" {
  type        = number
  default     = null
  description = "Maximum number of nodes in all node groups. Cluster autoscaler does not grow the cluster beyond this number."
}

variable "autoscaler_cores" {
  type = object({
    min = number
    max = number
  })
  default     = null
  description = "Minimum and maximum number of cores in cluster, in the format <min>:<max>. Cluster autoscaler does not scale the cluster beyond these numbers."
}

variable "autoscaler_memory" {
  type = object({
    min = number
    max = number
  })
  default     = null
  description = "Minimum and maximum number of gigabytes of memory in cluster, in the format <min>:<max>. Cluster autoscaler does not scale the cluster beyond these numbers."
}

variable "autoscaler_gpus" {
  type = list(object({
    type = string
    range = object({
      min = number
      max = number
    })
  }))
  default     = null
  description = "Minimum and maximum number of different GPUs in cluster, in the format <gpu_type>:<min>:<max>. Cluster autoscaler does not scale the cluster beyond these numbers. Can be passed multiple times."
}

variable "autoscaler_scale_down_enabled" {
  type        = bool
  default     = null
  description = "Should cluster-autoscaler scale down the cluster."
}

variable "autoscaler_scale_down_unneeded_time" {
  type        = string
  default     = null
  description = "How long a node should be unneeded before it is eligible for scale down."
}

variable "autoscaler_scale_down_utilization_threshold" {
  type        = string
  default     = null
  description = "Node utilization level, defined as sum of requested resources divided by capacity, below which a node can be considered for scale down."
}

variable "autoscaler_scale_down_delay_after_add" {
  type        = string
  default     = null
  description = "How long after scale up that scale down evaluation resumes."
}

variable "autoscaler_scale_down_delay_after_delete" {
  type        = string
  default     = null
  description = "How long after node deletion that scale down evaluation resumes."
}

variable "autoscaler_scale_down_delay_after_failure" {
  type        = string
  default     = null
  description = "How long after scale down failure that scale down evaluation resumes."
}

##############################################################
# default_ingress resource variables
##############################################################

variable "default_ingress_id" {
  type        = string
  default     = null
  description = "Unique identifier of the ingress."
}

variable "default_ingress_route_selectors" {
  type        = map(string)
  default     = null
  description = "Route Selectors for ingress. Format should be a comma-separated list of 'key=value'. If no label is specified, all routes are exposed on both routers. For legacy ingress support these are inclusion labels, otherwise they are treated as exclusion label."
}

variable "default_ingress_excluded_namespaces" {
  type        = list(string)
  default     = null
  description = "Excluded namespaces for ingress. Format should be a comma-separated list 'value1, value2...'. If no values are specified, all namespaces are exposed."
}

variable "default_ingress_route_wildcard_policy" {
  type        = string
  default     = null
  description = "Wildcard Policy for ingress. Options are [\"WildcardsDisallowed\", \"WildcardsAllowed\"]. Default is \"WildcardsDisallowed\"."
}

variable "default_ingress_route_namespace_ownership_policy" {
  type        = string
  default     = null
  description = "Namespace Ownership Policy for ingress. Options are [\"Strict\", \"InterNamespaceAllowed\"]. Default is \"Strict\"."
}

variable "default_ingress_cluster_routes_hostname" {
  type        = string
  default     = null
  description = "Components route hostname for oauth, console, download."
}

variable "default_ingress_load_balancer_type" {
  type        = string
  default     = null
  description = "Type of Load Balancer. Options are [\"classic\", \"nlb\"]`:with."
}

variable "default_ingress_cluster_routes_tls_secret_ref" {
  type        = string
  default     = null
  description = "Components route TLS secret reference for oauth, console, download."
}

#variable "admin_username" {
#  type = string
#}
#
#variable "admin_password" {
#  type = string
#}

variable "AWS_ACCESS_KEY_ID" {
  type = string  
}

variable "AWS_SECRET_ACCESS_KEY" {
  type = string
}

variable "cloud_region" {
  type    = string
  default = "us-east-2"
}