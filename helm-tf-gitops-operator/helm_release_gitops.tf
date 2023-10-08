resource "helm_release" "gitops-operator" {
  name        = "gitops-operator"
  chart       = "gitops-operator"
  repository  = "./charts"
  namespace   = "helm-gitops-operator"
  max_history = 3
  create_namespace = true
  wait             = true
  reset_values     = true
}