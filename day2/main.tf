data "shell_script" "token" {
    lifecycle_commands {
        read = <<-EOF
          echo "{\"ocp_token\": \"$(curl -s -k -i -L -X GET --user "${var.ocp_user}":"${var.ocp_pwd}" "${var.ocp_oauth_host}" | grep -oP "access_token=\K[^&]*")\"}"
        EOF
    }
}

output "ocp_token" {
    value = data.shell_script.token.output["ocp_token"]
    sensitive   = true
}

## Comment out everything below here to destroy resources
resource "helm_release" "gitops" {
  name        = "gitops"
  chart       = "gitops"
  repository  = "."
  namespace   = "helm-gitops"
  max_history = 3
  create_namespace = true
  wait             = true
  reset_values     = true
}

resource "helm_release" "master-app" {
  name        = "master-app"
  chart       = "master-app"
  repository  = "."
  namespace   = "helm-master-app"
  max_history = 3
  create_namespace = true
  wait             = true
  reset_values     = true
}