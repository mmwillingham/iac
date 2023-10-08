#provider "helm" {
#  kubernetes {
#    config_path = "~/.kube/config"
#  }
#}

provider "helm" {
  kubernetes {
  host = var.host
  username = var.username
  password = var.password    
  }
}