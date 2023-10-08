provider "openshift" {
  load_config_file = "false"

  host = "https://104.196.242.174"

  username = "bolauder"
  password = "Bolauder-password-123"
}

resource "kubernetes_namespace" "example" {
  metadata {
    annotations = {
      name = "example-annotation"
    }

    labels = {
      mylabel = "label-value"
    }

    name = "terraform-example-namespace"
  }
}