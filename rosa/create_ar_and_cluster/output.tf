output "account_role_prefix" {
  value = module.create_account_roles.account_role_prefix
}

output "cluster_id" {
  value = rhcs_cluster_rosa_classic.rosa_sts_cluster.id
}

output "api_url" {
  value = rhcs_cluster_rosa_classic.rosa_sts_cluster.api_url
}

output "console_url" {
  value = rhcs_cluster_rosa_classic.rosa_sts_cluster.console_url
}

output "current_version" {
  value = rhcs_cluster_rosa_classic.rosa_sts_cluster.current_version
}

output "domain" {
  value = rhcs_cluster_rosa_classic.rosa_sts_cluster.domain
}

output "ocm_properties" {
  value = rhcs_cluster_rosa_classic.rosa_sts_cluster.ocm_properties
}

output "state" {
  value = rhcs_cluster_rosa_classic.rosa_sts_cluster.state
}

output "ccs_enabled" {
  value = rhcs_cluster_rosa_classic.rosa_sts_cluster.ccs_enabled
}

output "oidc_thumbprint" {
  value = rhcs_cluster_rosa_classic.rosa_sts_cluster.sts.thumbprint
}

output "oidc_endpoint_url" {
  value = rhcs_cluster_rosa_classic.rosa_sts_cluster.sts.oidc_endpoint_url
}

