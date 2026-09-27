resource "aws_iam_role" "ec2" {
  name = "cloud-provisioner-${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "cloud-provisioner-${var.environment}-ec2-role"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_policy" "ec2_s3_list" {
  name        = "cloud-provisioner-${var.environment}-ec2-s3-list"
  description = "Allow EC2 to list S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "s3:ListAllMyBuckets"
        ]

        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_s3_list" {
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.ec2_s3_list.arn
}

resource "aws_iam_instance_profile" "ec2" {
  name = "cloud-provisioner-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2.name
}