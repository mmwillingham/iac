module "rosa-sts" {
  source  = "terraform-redhat/rosa-sts/aws"
  version = "0.0.15"
}

module "create_account_roles"{
   source = "terraform-redhat/rosa-sts/aws"
   version = "0.0.5"

   create_account_roles = true

   account_role_prefix      = var.account_role_prefix
   path                     = var.path
   ocm_environment          = var.ocm_environment
   rosa_openshift_version   = var.rosa_openshift_version
   account_role_policies    = var.account_role_policies
   all_versions             = var.all_versions
   operator_role_policies   = var.operator_role_policies

    #optional
    tags                    = {
      contact     = "xyz@company.com"
      cost-center = "12345"
      owner       = "productteam"
      environment = "test"
    }
}

data "rhcs_rosa_operator_roles" "operator_roles" {
  operator_role_prefix = var.operator_role_prefix
  account_role_prefix = var.account_role_prefix
}

module operator_roles {
    source = "terraform-redhat/rosa-sts/aws"
    version = "0.0.5"
    
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