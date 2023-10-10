provider "helm" {
  kubernetes {
    #config_path = "~/.kube/config"
    host = var.host
    username = var.username
    username = var.password
  }
}
