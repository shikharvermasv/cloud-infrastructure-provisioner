variable "github_subject" {
  description = "GitHub OIDC subject allowed to assume the ECR role"
  type        = string
}

variable "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  type        = string
}