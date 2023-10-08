resource "helm_release" "nginx" {
  name        = "nginx"
  chart       = "nginx"
  repository  = "."
  namespace   = "application"
  max_history = 3
  create_namespace = true
  wait             = true
  reset_values     = true
}