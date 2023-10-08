#provider "kubernetes" {
#
#  host = var.host
#
#  username = var.username
#  password = var.password
#}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_namespace" "example" {
  metadata {
    name = var.namespace
  }
}

