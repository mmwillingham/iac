provider "kubernetes" {
  load_config_file = "false"

  host = var.host

  username = var.username
  password = var.password
}

resource "kubernetes_namespace" "example" {
  metadata {
#    annotations = {
#      name = "example-annotation"
#    }

#    labels = {
#      mylabel = "label-value"
#    }

    name = var.namespace
  }
}