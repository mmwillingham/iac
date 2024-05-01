# https://github.com/terraform-redhat/terraform-aws-rosa-sts/blob/main/examples/operator_roles_and_oidc/create_rosa_sts_operator_roles_and_oidc.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.20.0"
    }
    rhcs = {
      version = ">= 1.0.0"
      source  = "terraform-redhat/rhcs"
    }
  }
}

provider "rhcs" {
  token = var.token
  url   = var.url
}


data "rhcs_rosa_operator_roles" "operator_roles" {
  operator_role_prefix = var.operator_role_prefix
  account_role_prefix = var.account_role_prefix
}

module operator_roles {
    source = "terraform-redhat/rosa-sts/aws"
    version = "0.0.5"
    
    create_account_roles = true    
    create_operator_roles = true
    create_oidc_provider = true

    cluster_id = rhcs_cluster_rosa_classic.rosa_sts_cluster.id
    rh_oidc_provider_thumbprint = rhcs_cluster_rosa_classic.rosa_sts_cluster.sts.thumbprint
    rh_oidc_provider_url = rhcs_cluster_rosa_classic.rosa_sts_cluster.sts.oidc_endpoint_url
    operator_roles_properties = data.rhcs_rosa_operator_roles.operator_roles.operator_iam_roles

    #optional
    tags                = {
      contact     = "xyz@company.com"
      cost-center = "12345"
      owner       = "productteam"
      environment = "test"
    }
}

resource "time_sleep" "wait_for_roles" {
  create_duration = "20s"
  depends_on = [ module.create_account_roles ]
}

resource "rhcs_cluster_rosa_classic" "rosa_sts_cluster" {
  name               = var.cluster_name
  cloud_region       = var.cloud_region
  #host_prefix        = var.host_prefix
  aws_account_id     = data.aws_caller_identity.current.account_id
  availability_zones = var.availability_zones
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
}

resource "rhcs_cluster_wait" "rosa_cluster" {
  cluster = rhcs_cluster_rosa_classic.rosa_sts_cluster.id
  timeout = 60 
}

#module operator_roles {
#    source = "terraform-redhat/rosa-sts/aws"
#    version = "0.0.5"
#
#    create_operator_roles = true
#    create_oidc_provider = true
#
#    cluster_id = rhcs_cluster_rosa_classic.rosa_sts_cluster.id
#    rh_oidc_provider_thumbprint = rhcs_cluster_rosa_classic.rosa_sts_cluster.sts.thumbprint
#    rh_oidc_provider_url = rhcs_cluster_rosa_classic.rosa_sts_cluster.sts.oidc_endpoint_url
#    operator_roles_properties = data.rhcs_rosa_operator_roles.operator_roles.operator_iam_roles
#
#    #optional
#    tags                = {
#      contact     = "xyz@company.com"
#      cost-center = "12345"
#      owner       = "productteam"
#      environment = "test"
#    }
#}


