resource "helm_release" "gitops" {
  name        = "gitops"
  chart       = "gitops"
  repository  = "./charts"
#  namespace   = "helm-gitops"
#  max_history = 3
#  create_namespace = true
#  wait             = true
#  reset_values     = true
}

#resource "helm_release" "example" {
#  name       = "my-local-chart"
#  chart      = "./charts/example"
#}