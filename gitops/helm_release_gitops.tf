resource "helm_release" "gitops" {
  name        = "gitops"
  chart       = "gitops"
  repository  = "./charts"
  namespace   = "helm-gitops"
  max_history = 3
  create_namespace = true
  wait             = true
  reset_values     = true
}