terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.23.0"
    }
  }
}

terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
      version = "2.11.0"
    }
  }
}


provider "kubernetes" {
    config_path = "~/.kube/config"
    config_context = "default/api-bosez123-qzzw-p1-openshiftapps-com:6443/bolauder"
}
