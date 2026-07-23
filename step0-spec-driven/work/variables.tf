variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-northeast-1"
}

variable "env" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "project" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "kiro-ws"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/20"
}

variable "public_subnets" {
  description = "Map of AZ to public subnet CIDR block"
  type        = map(string)
  default = {
    "ap-northeast-1a" = "10.0.0.0/26"
    "ap-northeast-1c" = "10.0.0.64/26"
  }
}

variable "private_ecs_task_subnets" {
  description = "Map of AZ to private ECS task subnet CIDR block"
  type        = map(string)
  default = {
    "ap-northeast-1a" = "10.0.2.0/23"
    "ap-northeast-1c" = "10.0.4.0/23"
  }
}

variable "private_data_subnets" {
  description = "Map of AZ to private data subnet CIDR block"
  type        = map(string)
  default = {
    "ap-northeast-1a" = "10.0.12.0/24"
    "ap-northeast-1c" = "10.0.13.0/24"
  }
}
