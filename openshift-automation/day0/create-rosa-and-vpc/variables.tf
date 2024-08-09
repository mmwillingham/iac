variable "token" {
  type      = string
  sensitive = true
}

variable "operator_role_prefix" {
  type = string
}

variable "url" {
  type        = string
  description = "Provide OCM environment by setting a value to url"
  default     = "https://api.openshift.com"
}

variable "account_role_prefix" {
  type = string
}

variable "cluster_name" {
  type    = string
  default = "my-cluster"
}

variable "cloud_region" {
  type    = string
  default = "us-east-2"
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-2a"]
}

variable "tags" {
  description = "List of AWS resource tags to apply."
  type        = map(string)
  default     = null
}

variable "ocm_environment" {
  type    = string
  default = "production"
}

variable "openshift_version" {
  type = string
  default = ""
}

variable "path" {
  description = "(Optional) The arn path for the account/operator roles as well as their policies."
  type        = string
  default = null
}

variable "admin_username" {
  type = string
}

variable "admin_password" {
  type = string
}

variable "AWS_ACCESS_KEY_ID" {
  type = string  
}

variable "AWS_SECRET_ACCESS_KEY" {
  type = string
}

variable "upgrade_acknowledgements_for" {
  description = "Requried for cluster upgades"
  type        = string
  default = ""
}

variable "multi_az" {
  type      = string
  sensitive = true
}

variable "replicas" {
  type        = number
  default     = null
  description = "Number of worker nodes to provision. This attribute is applicable solely when autoscaling is disabled. Single zone clusters need at least 2 nodes, multizone clusters need at least 3 nodes. Hosted clusters require that the number of worker nodes be a multiple of the number of private subnets. (default: 2)"
}
