resource "helm_release" "example" {
  name       = "my-local-chart"
  chart      = "./chart"
}
