resource "helm_release" "openshift-gitops" {
  name        = "openshift-gitops"
  chart       = "openshift-gitops"
  repository  = "./charts"
  namespace   = "helm-openshift-gitops "
  max_history = 3
  create_namespace = true
  wait             = true
  reset_values     = true
}