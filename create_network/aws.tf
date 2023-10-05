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

resource "aws_instance" "mmw-t2-micro" {
    ami = "ami-026b57f3c383c2eec"
    instance_type = "t2.micro"
    tags = {
      Name = "mmw-t2-micro"
  }
}

resource "aws_vpc" "mmw_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "mmw_vpc"
  }
}
