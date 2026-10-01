variable "environment" {
  type = string
}

variable "private_subnet_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "instance_profile_name" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "alb_security_group_id" {
  description = "Security group ID allowed to access the application on port 8000"
  type        = string
}