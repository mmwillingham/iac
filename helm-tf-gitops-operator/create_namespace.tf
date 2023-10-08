provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_namespace" "labs-ci-cd" {
  metadata {
    name = var.namespace
  }
}

