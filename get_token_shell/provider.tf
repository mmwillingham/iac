terraform {
  required_providers {
    # kubernetes = {
    #   source = "hashicorp/kubernetes"
    #   version = "2.23.0"
    # }
    shell = {
      source = "scottwinkler/shell"
      version = "1.7.10"
    }
    helm = {
      source = "hashicorp/helm"
      version = "2.11.0"
    }
  }
}

# provider "kubernetes" {
#   config_path = "~/.kube/config"
# }

provider "helm" {
 kubernetes {
   host     = "https://api.bosez123.qzzw.p1.openshiftapps.com:6443"
   token = data.shell_script.token.output["ocp_token"]
   insecure = true
   #config_path = "~/.kube/config"
 }
}

provider "shell" {
  # Configuration options
}

