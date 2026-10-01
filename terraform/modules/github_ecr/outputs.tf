output "role_arn" {
  description = "IAM role ARN used by GitHub Actions to push images to ECR"
  value       = aws_iam_role.github_ecr.arn
}