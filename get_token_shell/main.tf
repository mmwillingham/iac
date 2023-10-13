# resource "kubernetes_namespace" "example" {
#   metadata {
#     name = "helm-mmw"
#   }
# }

#comment

data "shell_script" "token" {
    lifecycle_commands {
        read = <<-EOF
          echo "{\"ocp_token\": \"$(curl -s -k -i -L -X GET --user "${var.ocp_user}":"${var.ocp_pwd}" "${var.ocp_oauth_host}" | grep -oP "access_token=\K[^&]*")\"}"
        EOF
    }
}

output "ocp_token" {
    value = data.shell_script.token.output["ocp_token"]
}

resource "helm_release" "mmw" {
  name        = "mmw"
  chart       = "mmw"
  repository  = "."
  namespace   = "helm-mmw"
  max_history = 3
  create_namespace = true
  wait             = true
  reset_values     = true
}


# curl that works
# curl -s -k -i -L -X GET --user bolauder:Bolauder-password-123 'https://oauth-openshift.apps.bosez123.qzzw.p1.openshiftapps.com/oauth/authorize?response_type=token&client_id=openshift-challenging-client' | grep -oP "access_token=\K[^&]*"

#          echo "{\"user\": \"$(whoami)\"}"

# data "shell_script" "token" {
#     lifecycle_commands {
#         read = <<-EOF
#           echo "{\"token\": \"$(curl -s -k -i -L -X GET --user bolauder:Bolauder-password-123 'https://oauth-openshift.apps.bosez123.qzzw.p1.openshiftapps.com/oauth/authorize?response_type=token&client_id=openshift-challenging-client' | grep -oP "access_token=\K[^&]*")\"}"
#         EOF
#     }
# }

# Not sure if these variables were passed
# data "shell_script" "token" {
#     lifecycle_commands {
#         read = <<-EOF
#           echo "{\"token\": \"$(curl -s -k -i -L -X GET --user var.ocp_user:var.ocp_pwd var.ocp_oauth_host | grep -oP "access_token=\K[^&]*")\"}"
#         EOF
#     }
# }

# export ocp_user=bolauder
# export ocp_pwd=Bolauder-password-123
# export ocp_oauth_host=https://oauth-openshift.apps.bosez123.qzzw.p1.openshiftapps.com/oauth/authorize?response_type=token&client_id=openshift-challenging-client
# ocp_oauth_host = https://oauth-openshift.apps.bosez123.qzzw.p1.openshiftapps.com/oauth/authorize?response_type=token&client_id=openshift-challenging-client
# ocp_user = "bolauder"
# ocp_pwd = "Bolauder-password-123"

# locals {
#   ocp_creds = {
#      ocp_user = var.ocp_user
#      ocp_pwd = var.ocp_pwd
#      ocp_oauth_host = var.ocp_oauth_host
#   }
# }

# data "shell_script" "token" {
#     lifecycle_commands {
#         read = <<-EOF
#           echo "{\"token\": \"$(curl -s -k -i -L -X GET --user "${local.ocp_creds.ocp_user}":"${local.ocp_creds.ocp_pwd}" "${local.ocp_creds.ocp_oauth_host}" | grep -oP "access_token=\K[^&]*")\"}"
#         EOF
#     }
# }
#
# curl -s -k -i -L -X GET --user bolauder:Bolauder-password-123 'https://oauth-openshift.apps.bosez123.qzzw.p1.openshiftapps.com/oauth/authorize?response_type=token&client_id=openshift-challenging-client' | grep -oP "access_token=\K[^&]*"
#echo "{\"token\": \"$(curl -s -k -i -L -X GET --user "${var.ocp_user}":"${var.ocp_pwd}" "${var.ocp_oauth_host}" | grep -oP "access_token=\K[^&]*")\"}"

# data "shell_script" "weather" {
#   lifecycle_commands {
#     read = <<-EOF
#         echo "{\"SanFrancisco\": \"$(curl wttr.in/SanFrancisco?format="%l:+%c+%t")\"}"
#     EOF
#   }
# }

# value is: "SanFrancisco: ⛅️ +54°F"
# output "weather" {
#   value = data.shell_script.weather.output["SanFrancisco"]
# }