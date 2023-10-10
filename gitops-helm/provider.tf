provider "kubernetes" {
    #config_path = "~/.kube/config"
    host = var.host
    username = var.username
    password = var.password
}
