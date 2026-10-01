data "aws_ssm_parameter" "amazon_linux" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_security_group" "private_ec2" {
  name        = "cloud-provisioner-${var.environment}-private-ec2-sg"
  description = "Security group for private EC2"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow application traffic from ALB"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "cloud-provisioner-${var.environment}-private-ec2-sg"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_instance" "private" {
  ami                         = data.aws_ssm_parameter.amazon_linux.value
  instance_type               = var.instance_type
  subnet_id                   = var.private_subnet_id
  iam_instance_profile        = var.instance_profile_name
  associate_public_ip_address = false

  vpc_security_group_ids = [
    aws_security_group.private_ec2.id
  ]

  user_data = <<-EOF
    #!/bin/bash
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
  EOF

  tags = {
    Name        = "cloud-provisioner-${var.environment}-private-ec2"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}