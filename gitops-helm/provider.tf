provider "helm" {
  kubernetes {
    #config_path = "~/.kube/config"
#    host = var.host
#    username = var.username
#    password = var.password
    host = "https://api.bosez123.qzzw.p1.openshiftapps.com:6443"
    username = "bolauder"
    password = "Bolauder-password-123"

  }
}

#provider "helm" {
#  kubernetes {
#    config_path = "~/.kube/config"
#  }
#}