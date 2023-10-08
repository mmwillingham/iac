provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "helm_release" "example" {
  name       = "my-local-chart"
  chart      = "./chart.yaml"
}
