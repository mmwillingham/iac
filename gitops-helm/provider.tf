provider "helm" {
  kubernetes {
    host     = "https://api.bosez123.qzzw.p1.openshiftapps.com:6443"
    token = "sha256~lkXy1_zQ24WmRBsR0iHM3wKtyHL_YWHzJo-KwHVdoTk"
    insecure = true
  }
}

terraform {
  required_providers {
    python = {
      source = "joaqquin89/python"
      version = "1.0.3"
    }
    helm = {
      source = "hashicorp/helm"
      version = "2.11.0"
    }
  }
}

# This works
# provider "helm" {
#   kubernetes {
#     config_path = "~/.kube/config"
#   }
# }


#terraform {
#  required_providers {
#    kubernetes = {
#      source = "hashicorp/kubernetes"
#      version = "2.23.0"
#    }
#    helm = {
#      source = "hashicorp/helm"
##      version = "2.11.0"
##    }
##  }
##}#
#
##provider "kubernetes" {
##    config_path = "~/.kube/config"
##    config_context = "default/api-bosez123-qzzw-p1-openshiftapps-com:6443/bolauder"
##}#
#
#provider "kubernetes" {
#  host     = "https://api.bosez123.qzzw.p1.openshiftapps.com"
#  username = "bolauder"
#  password = "Bolauder-password-123"
#  insecure = true
#  #client_certificate     = "${file("~/.kube/client-cert.pem")}"
#  #client_key             = "${file("~/.kube/client-key.pem")}"
#  #cluster_ca_certificate = "${file("~/.kube/cluster-ca-cert.pem")}"
#}