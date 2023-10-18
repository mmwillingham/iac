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

provider "helm" {
 kubernetes {
   host  = var.ocp_api_host
   token = data.shell_script.token.output["ocp_token"]
   insecure = true   
 }
}

provider "shell" {
  # Configuration options
}