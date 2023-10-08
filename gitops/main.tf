provider "kubernetes" {

  host = var.host

  username = var.username
  password = var.password
}

#resource "kubernetes_namespace" "example" {
#  metadata {
#    annotations = {
#      name = "example-annotation"
#    }

#    labels = {
#      mylabel = "label-value"
#    }
#
#    name = var.namespace
#  }
#}

resource "kubernetes_pod" "nginx" {
  metadata {
    name = "nginx-example"
    labels {
      App = "nginx"
    }
  }

  spec {
    container {
      image = "nginx:1.15.2"
      name  = "example"

      port {
        container_port = 80
      }
    }
  }
}