terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket       = "shikhar-cloud-provisioner-tfstate-2026"
    key          = "cloud-infrastructure-provisioner/dev/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source = "../../modules/vpc"

  environment         = var.environment
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  availability_zone   = var.availability_zone
}

module "ec2" {
  source = "../../modules/ec2"

  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  subnet_id             = module.vpc.public_subnet_id
  instance_type         = var.instance_type
  instance_profile_name = module.iam.instance_profile_name
}

module "iam" {
  source = "../../modules/iam"

  environment = var.environment
}

module "ssm" {
  source = "../../modules/ssm"

  environment = var.environment
}

module "private_ec2" {
  source = "../../modules/private_ec2"

  environment           = var.environment
  private_subnet_id     = module.vpc.private_subnet_id
  vpc_id                = module.vpc.vpc_id
  instance_profile_name = module.ssm.instance_profile_name
  instance_type         = "t3.micro"
}

module "vpc_endpoints" {
  source = "../../modules/vpc_endpoints"

  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = [module.vpc.private_subnet_id]
  security_group_ids = [module.private_ec2.security_group_id]
}

module "ecr" {
  source = "../../modules/ecr"

  repository_name = "cloud-provisioner-api"
  environment     = var.environment
}

module "github_ecr" {
  source = "../../modules/github_ecr"

  github_subject = "repo:shikharvermasv/cloud-infrastructure-provisioner:ref:refs/heads/main"

  ecr_repository_arn = module.ecr.repository_arn
}
# this is "moved" which is used to move to tf resources from one file to other with changes in the state file
# moved {
#   from = aws_vpc.main
#   to   = module.vpc.aws_vpc.main
# }

# moved {
#   from = aws_subnet.public
#   to   = module.vpc.aws_subnet.public
# }

# moved {
#   from = aws_internet_gateway.main
#   to   = module.vpc.aws_internet_gateway.main
# }

# moved {
#   from = aws_route_table.public
#   to   = module.vpc.aws_route_table.public
# }

# moved {
#   from = aws_route_table_association.public
#   to   = module.vpc.aws_route_table_association.public
# }

# moved {
#   from = aws_security_group.ec2
#   to   = module.ec2.aws_security_group.ec2
# }

# moved {
#   from = aws_instance.app
#   to   = module.ec2.aws_instance.app
# }