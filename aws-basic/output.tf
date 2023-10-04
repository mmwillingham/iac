output "instance_ip_addr" {
  value = aws_instance.server.private_ip
}

output "vpc_id" {
  description = "ID of project VPC"
  value       = module.vpc.vpc_id
}
