terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.20.0"
    }
    # Version 1.4.0 released 10/19/23
    rhcs = {
      source  = "terraform-redhat/rhcs"
      version = ">= 1.1.0"      
    }
    # helm = {
    #   source = "hashicorp/helm"
    #   version = "~> 2.11"
    # }
    # kubernetes = {
    #   source = "hashicorp/kubernetes"
    #   version = "2.23.0"
    # }
  }
}

provider "aws" {
  region = var.cloud_region  
}

provider "rhcs" {
  token = var.token
  url   = var.url
}

# +------------------------------------------------------+
# | Comment out everything below to destory the cluster  |
# +------------------------------------------------------+

locals {
  sts_roles = {
    role_arn         = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.account_role_prefix}-Installer-Role",
    support_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.account_role_prefix}-Support-Role",
    instance_iam_roles = {
      master_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.account_role_prefix}-ControlPlane-Role",
      worker_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.account_role_prefix}-Worker-Role"
    },
    operator_role_prefix = var.operator_role_prefix,
  }
}

data "aws_caller_identity" "current" {}
data "rhcs_policies" "all_policies" {}
data "rhcs_versions" "all" {}

module "create_account_roles" {
  source  = "terraform-redhat/rosa-sts/aws"
  version = "0.0.14"

  create_operator_roles = false
  create_oidc_provider  = false
  create_account_roles  = true
  account_role_prefix    = var.account_role_prefix
  ocm_environment        = var.ocm_environment
  rosa_openshift_version = regex("^[0-9]+\\.[0-9]+", var.openshift_version)
  account_role_policies  = data.rhcs_policies.all_policies.account_role_policies
  operator_role_policies = data.rhcs_policies.all_policies.operator_role_policies
  all_versions           = data.rhcs_versions.all
  path                   = var.path
  tags                   = var.tags    
}

#+------------------------------------------------------------+
#| Added this resource to allow time for create_account_roles |
#| to complete before cluster creation                        |
#+------------------------------------------------------------+
resource "time_sleep" "wait_for_roles" {
  create_duration = "20s"
  depends_on = [ module.create_account_roles ]
}

resource "rhcs_cluster_rosa_classic" "rosa_sts_cluster" {
  name               = var.cluster_name
  cloud_region       = var.cloud_region
  aws_account_id     = data.aws_caller_identity.current.account_id
  multi_az           = var.multi_az
  availability_zones = var.availability_zones
  replicas           = var.replicas
  properties = {
    rosa_creator_arn = data.aws_caller_identity.current.arn
  }
  sts = local.sts_roles  
  destroy_timeout = 60  
  depends_on = [time_sleep.wait_for_roles]
  version = var.openshift_version
  admin_credentials = {
     password = var.admin_password
     username = var.admin_username 
  }
  upgrade_acknowledgements_for = var.upgrade_acknowledgements_for  
}

resource "rhcs_cluster_wait" "rosa_cluster" {
  cluster = rhcs_cluster_rosa_classic.rosa_sts_cluster.id
  timeout = 60 
}

data "rhcs_rosa_operator_roles" "operator_roles" {
  operator_role_prefix = var.operator_role_prefix
  account_role_prefix  = var.account_role_prefix
}

module "operator_roles" {
  source  = "terraform-redhat/rosa-sts/aws"
  version = "0.0.14"

  create_operator_roles = true
  create_oidc_provider  = true
  create_account_roles  = false

  cluster_id                  = rhcs_cluster_rosa_classic.rosa_sts_cluster.id
  rh_oidc_provider_thumbprint = rhcs_cluster_rosa_classic.rosa_sts_cluster.sts.thumbprint
  rh_oidc_provider_url        = rhcs_cluster_rosa_classic.rosa_sts_cluster.sts.oidc_endpoint_url
  operator_roles_properties   = data.rhcs_rosa_operator_roles.operator_roles.operator_iam_roles
  tags                        = var.tags
}
