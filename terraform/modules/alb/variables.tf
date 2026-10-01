variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the ALB security group will be created"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet where the ALB will be placed"
  type        = string
}

variable "target_instance_id" {
  description = "Private EC2 instance to register with the target group"
  type        = string
}

variable "target_security_group_id" {
  description = "Security group ID of the private EC2"
  type        = string
}

variable "public_subnet_2_id" {
  description = "Second public subnet where the ALB will be placed"
  type        = string
}