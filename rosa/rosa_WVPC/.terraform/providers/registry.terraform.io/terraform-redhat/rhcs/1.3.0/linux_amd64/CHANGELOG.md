## 1.3.0 (Sep 27, 2023)
FEATURES:
* Private cluster - add new variable "private" indicates if the cluster has private connection
* Add support for creating cluster with pre-defined shared VPC
* Added new "rhcs_dns_domain" resource to allow reserving base domain before cluster creation.
* Support resources reconciliation - if a resource was removed without the use of the Terraform provider, executing "terraform apply" should prompt its recreation.
* Htpasswd identity provider - allow creating with multiple users
* Support MachinePool import into the terraform state

ENHANCEMENTS:
* Bug fixes
  * Adding http tokens default to terraform state in case its not returned
  * Terraform run or import failing after configuring 'additional-trust-bundle-file'
  * Provider produced inconsistent result after apply - additional_trust_bundle
  * Day one MachinePool - fix auto scaling/replicas validations
* Docs:
  * Add s3 missing permission for OIDC provider

## 1.2.4 (Sep 4, 2023)
ENHANCEMENTS:
* Fix for "Provider produced inconsistent result after apply" error when setting proxy.additional_trust_bundle

## 1.2.3 (Aug 24, 2023)
ENHANCEMENTS:
* Fixed a bug in cluster_rosa_resource -Terraform provider panic after adding additional CA bundle to ROSA cluster

## 1.2.2 (Aug 3, 2023)
ENHANCEMENTS:
* Update the documentation files to point the correct links.

## 1.2.1 (Aug 3, 2023)
ENHANCEMENTS:
* Update the documentation files to point the correct links.
* Fix the default value of openshift_version in the examples

## 1.2.0 (Aug 1, 2023)
FEATURES:
* Enable creating cluster admin in cluster create
* Add support for cluster properties update and delete

ENHANCEMENTS:
* Update the documentation files
* identity_provider resource can be imported by terraform import command
* rosa_cluster resource can be imported by terraform import command
* Remove AWS validations from rosa_cluster resource
* Recreate IDP tf resource if it was deleted not from tf
* Recreate rosa_cluster tf resource if it was deleted not from tf
* Recreate MachinePool tf resource if it was deleted not from tf
* Bug fixes:
  * populate rosa_rf_version with cluster properties
  * Cluster properties are now allowed to be added in Day1 and be changed in Day 2
  * TF-provider support creating a single-az machinepool for multi-az cluster
  * Improve error message: replica or autoscaling should be required parameters for creating additional machinepools
  * Validate OCP version in create_account_roles module
  * Support in generated account_role_prefix by terraform provider

## 1.1.0 (Jul 5, 2023)
ENHANCEMENTS:
* Update the documentation files
* Openshift Cluster upgrade improvements
* Add support for cluster properties update and delete

## 1.0.5 (Jun 29, 2023)
FEATURES:
* Add an options to set version in oidc clusters
* Add update/remove taints from machine pool
* Support edit/delete labels of secondary machine pool
* Create new topics on Terraform vars and modifying machine pools.
* Support upgrade cluster 

ENHANCEMENTS:
* Rename all resources prefix to start with `rhcs` (instead of `ocm`)
* Rename "terraform-provider-ocm" to "terraform-provider-rhcs"
* Improve examples
* Remove mandatory openshift-v prefix from create cluster version attribute
* Update the documentation files
* Update CI files
* Fix path also to be used for the operator roles creation
* Fix use_spot_instances attribute usage in machinepool resource

## 1.0.2 (Jun 21, 2023)
FEATURES:
* Added GitHub IDP provider support
* Added Google IDP provider support
* Adding support for http_tokens_state field.
* Added day 2 proxy settings
* Support cluster update/upgrade

ENHANCEMENTS:
* Add and improve documentations and examples
* Improve tests coverage
* Adjust rosa_cluster_resource to support OIDC config ID as an input attribute
* Improve the provider logger

## 1.0.0 (April 4, 2023)
ENHANCEMENTS:
* Bug fixes - Validate that the cluster version is compatible to the selected account roles' version in `cluster_rosa_classic` resource 

## 0.0.3 (Mar 28, 2023)
FEATURES:
* Add `ocm_policies` data source for getting the account role policies and operator role policies from OCM API.

ENHANCEMENTS:
* Add domain attribute to `cluster_rosa_classic` resource
* Bug fixes
  * update the descriptions of several attributes in `cluster_rosa_classic` resource.
  * Stop waiting when the cluster encounters an error state
* Add end-to-end test


## 0.0.2 (Feb 21, 2023)
FEATURES:
* Add `cluster_waiter` resource for addressing the cluster state in cluster creation scenario

ENHANCEMENTS:
* Add BYO OIDC support in `cluster_rosa_classic` resource
* Address cluster state while destroying the cluster_rosa_classic resource
* Add gitlab `identity_provider` resource


## 0.0.1 (Feb 12, 2023)
RESOURCES:
* ocm_cluster
* ocm_cluster_rosa_classic
* ocm_group_membership
* ocm_identity_provider
* ocm_machine_pool

DATA SOURCES: 
* ocm_cloud_providers
* ocm_rosa_operator_roles
* ocm_groups
* ocm_machine_types
* ocm_versions

ENHANCEMENTS:
* Move to a new GitHub organization `terraform-redhat`
* Update the documentation files to be generated by `tfplugindocs` tool
