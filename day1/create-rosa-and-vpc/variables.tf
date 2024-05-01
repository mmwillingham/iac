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

variable "tags" {
  description = "(optional) List of AWS resource tags to apply."
  type        = map(string)
  default = {
    contact     = "xyz@company.com"
    cost-center = "12345"
    owner       = "productteam"
    environment = "test"
  }
}

variable "account_role_prefix" {
  type = string
}

variable "ocm_environment" {
  type    = string
  default = "production"
}

variable "cluster_name" {
  type    = string
  default = "mmw-cluster"
}

# variable "host_prefix" {
#   type    = string
#   default = "mmw_prefix"
# }


variable "cloud_region" {
  type    = string
  default = "us-east-2"
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-2a"]
}

variable "openshift_version" {
  type = string
  default = ""
}

variable "path" {
  description = "(Optional) The arn path for the account/operator roles as well as their policies."
  type        = string
  default     = null
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

variable "private" {
  type = string
  default = "false"
}

variable "AWS_SECRET_ACCESS_KEY" {
  type = string
}
