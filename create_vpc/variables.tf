variable "name" {
  description = "Name to be used on all the resources as identifier"
  type        = string
  default     = ""
}

variable "aws_region" {
  default = "us-east-2"
}

variable "environment" {
  default = "prod"
}

variable "vpc_cidr" {
  default     = "10.0.0.0/16"
  description = "CIDR block of the vpc"
}

variable "public_subnets_cidr" {
  type        = list(any)
#  default     = ["10.0.0.0/20", "10.0.128.0/20"]
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  description = "CIDR block for Public Subnet"
}

variable "private_subnets_cidr" {
  type        = list(any)
#  default     = ["10.0.16.0/20", "10.0.144.0/20"]
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  description = "CIDR block for Private Subnet"
}
