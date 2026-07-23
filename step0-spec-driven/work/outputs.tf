output "private_data_subnet_ids" {
  description = "List of private data subnet IDs"
  value       = [for subnet in aws_subnet.private_data : subnet.id]
}

output "private_ecs_task_subnet_ids" {
  description = "List of private ECS task subnet IDs"
  value       = [for subnet in aws_subnet.private_ecs_task : subnet.id]
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = [for subnet in aws_subnet.public : subnet.id]
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "vpc_endpoint_sg_id" {
  description = "Security group ID for VPC endpoints"
  value       = aws_security_group.vpc_endpoints.id
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}
