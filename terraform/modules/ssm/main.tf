resource "aws_iam_role" "ssm" {
  name = "cloud-provisioner-${var.environment}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "ec2.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name        = "cloud-provisioner-${var.environment}-ssm-role"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "ecr_pull" {
  name = "cloud-provisioner-${var.environment}-ecr-pull"
  role = aws_iam_role.ssm.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "ecr:GetAuthorizationToken"
        ]

        Resource = "*"
      },
      {
        Effect = "Allow"

        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]

        Resource = "arn:aws:ecr:us-east-1:194722443160:repository/cloud-provisioner-api"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ssm" {
  name = "cloud-provisioner-${var.environment}-ssm-profile"
  role = aws_iam_role.ssm.name
}