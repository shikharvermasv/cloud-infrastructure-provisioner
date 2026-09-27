# Cloud Infrastructure Provisioner

A modular Infrastructure-as-Code project that provisions AWS cloud infrastructure using Terraform and deploys it through GitHub Actions with secure AWS OIDC authentication.

The project demonstrates automated infrastructure provisioning, remote Terraform state management, IAM-based access, private EC2 management through AWS Systems Manager, VPC interface endpoints, and controlled CI/CD deployment workflows.

---

## Architecture

```text
                                  GitHub
                                     |
                          Push / Pull Request
                                     |
                                     v
                              GitHub Actions
                                     |
                     +---------------+---------------+
                     |                               |
                     v                               v
              Terraform Validate              Terraform Plan
                                                     |
                                                     v
                                            Plan Artifact
                                                     |
                                                     v
                                           Environment Approval
                                                     |
                                                     v
                                              Terraform Apply
                                                     |
                                                     | OIDC
                                                     v
                                      AWS IAM Deployment Role
                                                     |
                                                     v
                                                  Terraform
                                                     |
                          +--------------------------+------------------+
                          |                                             |
                          v                                             v
                    S3 Remote State                                AWS VPC
                                                                        |
                                          +-----------------------------+------------------+
                                          |                                                |
                                          v                                                v
                                   Public Subnet                                      Private Subnet
                                          |                                                |
                                          v                                                v
                                     Public EC2                                      Private EC2
                                                                                         |
                                                                                         v
                                                                              VPC Interface Endpoints
                                                                                         |
                                                                                         v
                                                                                AWS Systems Manager
```

---

## Project Overview

This project is a modular AWS infrastructure provisioning platform built using Terraform and deployed through GitHub Actions.

It provisions and manages AWS networking, compute, IAM, and Systems Manager resources using Infrastructure as Code.

The project demonstrates:

* Modular Terraform infrastructure
* AWS VPC networking
* Public and private subnet architecture
* EC2 provisioning
* IAM roles and instance profiles
* Private EC2 management using AWS Systems Manager
* VPC interface endpoints
* S3 remote Terraform state
* GitHub Actions CI/CD
* GitHub OIDC authentication
* Protected infrastructure deployment with manual approval
* Infrastructure lifecycle management

---

## What I Built

This project was built to simulate a real-world cloud infrastructure deployment workflow rather than manually creating AWS resources through the AWS Console.

The infrastructure is defined using reusable Terraform modules and includes:

* A custom AWS VPC
* Public and private subnets
* Internet Gateway and route tables
* Public and private EC2 instances
* IAM roles and instance profiles
* AWS Systems Manager integration
* Private VPC interface endpoints for Systems Manager
* S3 remote Terraform state
* GitHub Actions CI/CD
* GitHub OIDC-based AWS authentication
* Protected deployment approval before Terraform Apply

The infrastructure can be created, validated, planned, deployed, managed, and destroyed through Infrastructure as Code.

The project also focuses on understanding the security and operational considerations involved in deploying Terraform from a CI/CD pipeline, including IAM trust policies, temporary AWS credentials, remote state, deployment permissions, and private instance management.

---

## Key Features

* Modular Terraform architecture
* AWS VPC provisioning
* Public and private subnet architecture
* Internet Gateway
* Route tables and route associations
* Security groups
* Public EC2 instance
* Private EC2 instance
* IAM roles and policies
* IAM instance profiles
* AWS Systems Manager integration
* SSM VPC interface endpoints
* S3 remote Terraform state
* GitHub Actions CI/CD
* GitHub OIDC federation
* Temporary AWS credentials through OIDC
* GitHub Environment approval before Terraform Apply
* Automated Terraform formatting checks
* Automated Terraform validation
* Terraform Plan artifact
* Infrastructure provisioning and destruction through Terraform

---

# Technology Stack

| Technology          | Purpose                        |
| ------------------- | ------------------------------ |
| AWS                 | Cloud infrastructure           |
| Terraform           | Infrastructure as Code         |
| GitHub Actions      | CI/CD automation               |
| GitHub OIDC         | Secure AWS authentication      |
| Amazon VPC          | Network infrastructure         |
| Amazon EC2          | Compute                        |
| AWS IAM             | Identity and access management |
| AWS Systems Manager | Private EC2 management         |
| Amazon S3           | Terraform remote state         |
| Linux               | EC2 operating environment      |
| Git / GitHub        | Version control                |

---

# AWS Architecture

## VPC

The project creates an AWS VPC to provide an isolated network for the infrastructure.

Example VPC CIDR:

```text
10.0.0.0/16
```

The VPC contains public and private subnets.

---

## Public Subnet

Example CIDR:

```text
10.0.1.0/24
```

The public subnet is associated with a route table that routes internet-bound traffic through an Internet Gateway.

The public EC2 instance is deployed into this subnet.

---

## Private Subnet

Example CIDR:

```text
10.0.2.0/24
```

The private subnet is used for infrastructure that should not require direct public internet exposure.

The private EC2 instance is managed through AWS Systems Manager.

---

## Internet Gateway

The Internet Gateway provides internet connectivity for resources deployed in the public subnet.

The public route table contains a default route through the Internet Gateway.

---

## Route Tables

Route tables control network traffic within the VPC.

The project uses separate routing configuration for the public and private subnet architecture.

---

## Security Groups

Security groups control network traffic to the EC2 instances.

The project uses security groups to control inbound and outbound traffic according to the role of each instance.

---

# EC2 Infrastructure

The project provisions both public and private EC2 infrastructure.

```text
AWS VPC
 |
 +---- Public Subnet
 |       |
 |       +---- Public EC2
 |
 +---- Private Subnet
         |
         +---- Private EC2
```

The EC2 instances use IAM instance profiles rather than storing AWS credentials directly on the instances.

---

# IAM Architecture

The project separates IAM permissions for CI/CD and EC2 workloads.

```text
GitHub Actions
      |
      +---- Terraform Deployment Role


Public EC2
      |
      +---- EC2 IAM Role


Private EC2
      |
      +---- SSM IAM Role
```

This separation prevents the EC2 runtime roles from being used as the GitHub Actions deployment identity.

The GitHub Actions deployment role is dedicated to Terraform infrastructure operations.

---

# AWS Systems Manager

The private EC2 instance is configured to work with AWS Systems Manager.

The architecture is:

```text
Private EC2
     |
     v
VPC Interface Endpoints
     |
     +---- SSM
     |
     +---- SSM Messages
     |
     +---- EC2 Messages
     |
     v
AWS Systems Manager
```

The private EC2 instance uses an IAM role with the required Systems Manager permissions.

This allows the instance to be managed without requiring direct public SSH access.

The private EC2 instance was successfully accessed and managed using AWS Systems Manager Session Manager during project validation.

---

# VPC Interface Endpoints

The project creates interface VPC endpoints for Systems Manager communication.

The configured endpoints include:

* `ssm`
* `ssmmessages`
* `ec2messages`

These endpoints provide private connectivity between the private EC2 instance and AWS Systems Manager services.

This allows the private EC2 instance to communicate with Systems Manager without requiring direct internet access.

---

# Terraform Architecture

The Terraform configuration is organized into reusable modules.

```text
terraform/
|
+-- environment/
|   |
|   +-- dev/
|       |
|       +-- main.tf
|       +-- variables.tf
|       +-- outputs.tf
|       +-- providers.tf
|       +-- backend.tf
|       +-- terraform.tfvars.example
|
+-- modules/
    |
    +-- vpc/
    |
    +-- ec2/
    |
    +-- private_ec2/
    |
    +-- iam/
    |
    +-- ssm/
    |
    +-- vpc_endpoints/
```

---

# Module Responsibilities

## VPC Module

Responsible for:

* VPC
* Public subnet
* Private subnet
* Internet Gateway
* Route tables
* Route table associations
* Network configuration

---

## EC2 Module

Responsible for:

* Public EC2 instance
* EC2 security group
* Instance configuration
* IAM instance profile association

---

## Private EC2 Module

Responsible for:

* Private EC2 instance
* Private subnet deployment
* Private instance configuration
* Private network access

---

## IAM Module

Responsible for:

* EC2 IAM role
* EC2 IAM policy
* IAM policy attachment
* EC2 instance profile

---

## SSM Module

Responsible for:

* SSM IAM role
* SSM policy attachment
* SSM instance profile
* Systems Manager integration

---

## VPC Endpoints Module

Responsible for:

* SSM VPC endpoint
* SSM Messages VPC endpoint
* EC2 Messages VPC endpoint

---

# Repository Structure

```text
cloud-infrastructure-provisioner/
|
+-- .github/
|   |
|   +-- workflows/
|       |
|       +-- terraform.yml
|
+-- backend/
|
+-- terraform/
|   |
|   +-- environment/
|   |   |
|   |   +-- dev/
|   |
|   +-- modules/
|       |
|       +-- ec2/
|       +-- iam/
|       +-- private_ec2/
|       +-- ssm/
|       +-- vpc/
|       +-- vpc_endpoints/
|
+-- tests/
|
+-- .gitignore
+-- README.md
```

---

# CI/CD Pipeline

The project uses GitHub Actions to automate Terraform validation, planning, and deployment.

The workflow is located at:

```text
.github/workflows/terraform.yml
```

---

## Pull Request Flow

```text
Pull Request
      |
      v
Terraform Format Check
      |
      v
Terraform Init
      |
      v
Terraform Validate
```

Pull requests are validated before changes are merged.

---

## Main Branch Deployment

When changes are pushed to the `main` branch:

```text
Push to main
      |
      v
Terraform Format Check
      |
      v
Terraform Init
      |
      v
Terraform Validate
      |
      v
Terraform Plan
      |
      v
Upload Terraform Plan
      |
      v
Environment Approval
      |
      v
Terraform Apply
      |
      v
AWS Infrastructure
```

This separates infrastructure validation, planning, approval, and deployment.

---

# Manual Workflow Execution

The workflow also supports manual execution through GitHub Actions.

From GitHub:

```text
Actions
   |
   +-- Terraform CI/CD
          |
          +-- Run workflow
```

The workflow can be manually triggered against the `main` branch.

---

# GitHub OIDC Authentication

The project uses GitHub OpenID Connect instead of storing long-lived AWS access keys in GitHub Actions.

The authentication flow is:

```text
GitHub Actions
      |
      | OIDC Token
      v
GitHub OIDC Provider
      |
      v
AWS STS
      |
      v
IAM Deployment Role
      |
      v
Temporary AWS Credentials
      |
      v
Terraform
```

The dedicated AWS IAM role used by GitHub Actions is:

```text
GitHubActions-Terraform-CloudProvisioner
```

GitHub Actions assumes this role using:

```text
sts:AssumeRoleWithWebIdentity
```

The IAM trust policy restricts which GitHub repository and GitHub Environment can assume the role.

---

# Why GitHub OIDC?

Instead of storing long-lived AWS access keys in GitHub Secrets, this project uses OIDC to obtain temporary AWS credentials.

Benefits include:

* No long-lived AWS credentials stored in GitHub
* Temporary AWS credentials
* IAM-controlled trust relationship
* Repository and environment restrictions
* Separation between GitHub and AWS authentication

---

# GitHub Environment Approval

Terraform Apply is protected using the GitHub Environment:

```text
terraform-apply
```

The deployment flow is:

```text
Terraform Plan
      |
      v
Terraform Plan Artifact
      |
      v
Protected Environment
      |
      v
Manual Approval
      |
      v
Terraform Apply
```

This provides a manual approval gate before infrastructure changes are applied.

---

# Terraform Remote State

Terraform uses Amazon S3 as its remote backend.

Remote state provides:

* Persistent Terraform state
* State availability across CI/CD runners
* Centralized state storage
* Support for automated deployments

The Terraform state file is not committed to Git.

The development backend bucket used by the project is:

```text
shikhar-cloud-provisioner-tfstate-2026
```

The backend is maintained separately from the infrastructure resources managed by the Terraform configuration.

---

# Terraform Configuration

Example development configuration:

```hcl
environment         = "dev"
vpc_cidr            = "10.0.0.0/16"
public_subnet_cidr  = "10.0.1.0/24"
availability_zone   = "us-east-1a"
instance_type       = "t2.micro"
private_subnet_cidr = "10.0.2.0/24"
```

The actual:

```text
terraform.tfvars
```

file is excluded from Git.

A template is provided:

```text
terraform.tfvars.example
```

---

# Local Setup

## Prerequisites

Install:

* Terraform
* AWS CLI
* Git
* An AWS account

Verify Terraform:

```powershell
terraform version
```

Verify AWS CLI:

```powershell
aws --version
```

Verify AWS authentication:

```powershell
aws sts get-caller-identity
```

---

# Initialize Terraform

Navigate to the development environment:

```powershell
cd terraform/environment/dev
```

Initialize Terraform:

```powershell
terraform init
```

---

# Create Variables File

## Windows

```powershell
copy terraform.tfvars.example terraform.tfvars
```

## Linux / macOS

```bash
cp terraform.tfvars.example terraform.tfvars
```

Update the values in `terraform.tfvars` if required.

---

# Format Terraform

Format the configuration:

```powershell
terraform fmt -recursive
```

Check formatting without modifying files:

```powershell
terraform fmt -check -recursive
```

---

# Validate Terraform

Run:

```powershell
terraform validate
```

This validates the Terraform configuration and reports syntax or configuration errors.

---

# Terraform Plan

Generate an execution plan:

```powershell
terraform plan
```

Review the resources Terraform intends to create, modify, or destroy.

---

# Terraform Apply

To deploy the infrastructure locally:

```powershell
terraform apply
```

Review the proposed changes before confirming.

For CI/CD deployments, Terraform Apply is executed through GitHub Actions after the protected environment approval.

---

# Terraform Destroy

When the infrastructure is no longer required:

```powershell
terraform destroy
```

Terraform will display the resources that will be removed.

Review the destruction plan carefully and confirm with:

```text
yes
```

The S3 backend should be treated separately because it stores Terraform state.

---

# Security Practices

The project demonstrates several security practices.

## GitHub OIDC

Long-lived AWS credentials are not stored in GitHub Actions.

GitHub uses OIDC to assume a dedicated AWS IAM role.

## IAM Roles

EC2 instances use IAM roles instead of hard-coded AWS credentials.

## Private Infrastructure

The private EC2 instance is deployed into a private subnet.

## Systems Manager

AWS Systems Manager is used to manage the private EC2 instance.

## VPC Endpoints

Interface VPC endpoints provide private connectivity to Systems Manager services.

## Deployment Approval

Terraform Apply requires approval through the protected GitHub Environment.

## Remote State

Terraform state is stored remotely in Amazon S3 rather than committed to Git.

---

# CI/CD Security Model

The deployment architecture can be summarized as:

```text
GitHub Repository
       |
       v
GitHub Actions
       |
       | OIDC
       v
AWS IAM Deployment Role
       |
       | Temporary Credentials
       v
Terraform
       |
       v
AWS Infrastructure
```

The GitHub Actions deployment role is separate from the EC2 instance roles.

```text
CI/CD Permissions
        !=
EC2 Runtime Permissions
```

This separation reduces the risk of using workload permissions for infrastructure deployment.

---

# Testing and Validation

The CI/CD workflow currently performs Terraform validation before deployment.

Current validation includes:

```text
terraform fmt -check -recursive
terraform init
terraform validate
terraform plan
```

The deployment process also generates a Terraform Plan before Apply.

```text
Terraform Plan
      |
      v
Review / Approval
      |
      v
Terraform Apply
```

This provides an opportunity to review infrastructure changes before they are applied.

Automated infrastructure testing is planned as a future improvement.

---

# Challenges Solved

## GitHub OIDC Trust Policy

The initial OIDC trust relationship did not match the actual subject claim generated by the GitHub Environment.

The OIDC token claims were inspected and the AWS IAM trust policy was updated to match the repository and environment subject.

This provided practical experience working with:

* GitHub OIDC
* IAM trust policies
* OIDC subject claims
* AWS STS
* `AssumeRoleWithWebIdentity`

---

## IAM Permissions

The GitHub Actions deployment role initially lacked several permissions required by Terraform during resource creation.

The missing permissions were identified from AWS authorization errors and added incrementally to the dedicated deployment policy.

Examples included:

```text
iam:CreateRole
iam:TagRole
iam:CreateInstanceProfile
iam:AddRoleToInstanceProfile
```

This provided practical experience troubleshooting AWS IAM authorization failures and understanding how Terraform resource operations map to AWS API permissions.

Further IAM permission tightening and resource-level restrictions are planned as a future improvement.

---

## Private EC2 and Systems Manager

The private EC2 instance required additional configuration for Systems Manager connectivity.

The final configuration uses:

* SSM IAM permissions
* SSM Agent
* VPC interface endpoints
* VPC DNS support

The private EC2 instance was successfully managed through AWS Systems Manager Session Manager.

---

# Lessons Learned

This project provided hands-on experience with:

* Terraform Infrastructure as Code
* Terraform module design
* AWS VPC networking
* Public and private subnets
* Route tables
* Internet Gateway
* Security groups
* EC2 provisioning
* IAM roles
* IAM policies
* IAM instance profiles
* AWS Systems Manager
* VPC interface endpoints
* S3 remote Terraform state
* GitHub Actions
* GitHub OIDC
* AWS STS
* IAM trust policies
* CI/CD environment approvals
* Terraform state management
* AWS permission troubleshooting
* Infrastructure lifecycle management

---

# Future Improvements

Potential future improvements include:

* Further tightening IAM permissions
* Additional Terraform variable validation
* Automated Terraform infrastructure tests
* Multiple Terraform environments
* Improved Terraform Plan reporting
* Cost monitoring and budget alerts
* Infrastructure drift detection
* Automated application deployment
* Dockerized application deployment
* Amazon ECR integration
* Amazon ECS deployment
* Application Load Balancer integration
* Monitoring and logging

These features are planned separately and are not part of the current implementation.

---

# Project Outcomes

The project successfully demonstrates an end-to-end Infrastructure-as-Code CI/CD workflow.

```text
Developer
    |
    v
GitHub
    |
    v
GitHub Actions
    |
    +---- Terraform Format
    |
    +---- Terraform Validate
    |
    +---- Terraform Plan
    |
    v
Environment Approval
    |
    v
GitHub OIDC
    |
    v
AWS IAM Role
    |
    v
Terraform Apply
    |
    v
AWS Infrastructure
```

The infrastructure can be:

* Provisioned using Terraform
* Validated through CI/CD
* Planned before deployment
* Applied after approval
* Managed through AWS Systems Manager
* Destroyed using Terraform

---

# Project Status

| Component                      | Status  |
| ------------------------------ | ------- |
| Terraform Infrastructure       | ✅       |
| Terraform Modules              | ✅       |
| AWS VPC                        | ✅       |
| Public Subnet                  | ✅       |
| Private Subnet                 | ✅       |
| EC2                            | ✅       |
| IAM                            | ✅       |
| AWS Systems Manager            | ✅       |
| VPC Interface Endpoints        | ✅       |
| S3 Remote State                | ✅       |
| GitHub Actions                 | ✅       |
| GitHub OIDC                    | ✅       |
| Environment Approval           | ✅       |
| Terraform Validation           | ✅       |
| Infrastructure Destroy         | ✅       |
| Automated Infrastructure Tests | Planned |
| IAM Least-Privilege Tightening | Planned |

---

# Author

**Shikhar Verma**

B.Tech Information Technology

Cloud / DevOps Engineer

### Technologies

* AWS
* Terraform
* GitHub Actions
* GitHub OIDC
* Python
* Linux
* Docker
* Git
* CI/CD
* Infrastructure as Code
* Cloud Infrastructure

### GitHub

https://github.com/shikharvermasv

---

# License

This project is intended for educational, learning, and portfolio purposes.