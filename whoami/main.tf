terraform {
  required_providers {
    shell = {
      source = "scottwinkler/shell"
      version = "1.7.10"
    }
  }
}

provider "shell" {
  # Configuration options
}

data "shell_script" "user" {
    lifecycle_commands {
        read = <<-EOF
          echo "{\"user\": \"$(oc whoami)\"}"
        EOF
    }
}
# "user" can be accessed like a normal Terraform map
output "user" {
    value = data.shell_script.user.output["user"]
}

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