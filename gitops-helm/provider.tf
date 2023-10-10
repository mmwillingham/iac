provider "helm" {
    #config_path = "~/.kube/config"
    host = var.host
    username = var.username
    password = var.password
}
