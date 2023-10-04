terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 4.6"
    }
  }
}

provider "aws" {
    region = "us-east-2"
 }

resource "aws_instance" "mmw.t2.micro" {
    ami = "ami-026b57f3c383c2eec"
    instance_type = "t2.micro"
}
