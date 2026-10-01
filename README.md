# Cloud Infrastructure Provisioning & Deployment Platform

A modular AWS Infrastructure-as-Code project that provisions cloud infrastructure using **Terraform** and demonstrates a secure application deployment workflow using **GitHub Actions, GitHub OIDC, Amazon ECR, Docker, AWS Systems Manager, and an Application Load Balancer**.

The project was built to simulate a real-world cloud infrastructure and deployment environment while keeping the architecture reproducible, modular, and cost-conscious.

---

## Overview

The project provisions an AWS environment containing:

* A custom VPC
* Public and private subnets
* Internet Gateway
* Public and private route tables
* Security groups
* Private EC2 application host
* AWS Systems Manager integration
* VPC endpoints for private AWS service connectivity
* Amazon ECR
* Application Load Balancer
* Terraform remote state in Amazon S3
* GitHub Actions CI/CD
* GitHub OIDC authentication
* Dockerized FastAPI application deployment

The infrastructure is defined as code using reusable Terraform modules.

The application deployment flow was validated end-to-end:

```text
GitHub
   |
   v
GitHub Actions
   |
   v
Amazon ECR
   |
   v
Private EC2
   |
   v
Docker
   |
   v
FastAPI
   |
   v
Application Load Balancer
   |
   v
Internet
```

The AWS infrastructure used for validation was subsequently destroyed using Terraform to avoid leaving unnecessary billable resources running.

---

# Architecture

```text
                              Internet
                                  |
                                  v
                       +---------------------+
                       | Application Load    |
                       | Balancer            |
                       | HTTP :80            |
                       +----------+----------+
                                  |
                           HTTP :8000
                                  |
                                  v
                    +-------------------------+
                    | Private EC2             |
                    |                         |
                    | Docker                  |
                    | FastAPI :8000           |
                    +-----------+-------------+
                                |
              +-----------------+------------------+
              |                 |                  |
              v                 v                  v
         ECR Endpoints    SSM Endpoints       S3 Gateway
              |                 |                  |
              v                 v                  |
         Amazon ECR       AWS Systems Manager      |
                                                   |
                                                   v
                                          Terraform State


GitHub
   |
   v
GitHub Actions
   |
   | OIDC
   v
AWS IAM
   |
   v
Temporary AWS Credentials
   |
   v
Amazon ECR
```

The application EC2 instance is intentionally placed in a **private subnet** and does not receive a public IP address.

External application traffic reaches the instance through the **Application Load Balancer**.

---

# Architecture Components

## VPC

The project creates an isolated AWS VPC.

```text
VPC CIDR: 10.0.0.0/16
```

The VPC contains:

```text
VPC
|
+-- Public Subnet
|     10.0.1.0/24
|     us-east-1a
|
+-- Public Subnet 2
|     10.0.3.0/24
|     us-east-1b
|
+-- Private Subnet
      10.0.2.0/24
      us-east-1a
```

The second public subnet exists because an AWS Application Load Balancer requires subnets in at least two Availability Zones.

---

## Public Subnets

The public subnets have routes through an Internet Gateway.

They are used by the Application Load Balancer.

```text
Public Subnet
     |
     v
Route Table
     |
     v
Internet Gateway
     |
     v
Internet
```

The Application Load Balancer is deployed across:

* `us-east-1a`
* `us-east-1b`

---

## Private Subnet

The application EC2 instance is deployed in:

```text
10.0.2.0/24
us-east-1a
```

The instance:

* Has no public IP
* Is not directly exposed to the Internet
* Receives application traffic only from the ALB security group
* Uses AWS Systems Manager for administration
* Uses VPC endpoints for required AWS service connectivity

---

# Application Load Balancer

The Application Load Balancer provides the public entry point for the application.

```text
Internet
   |
   v
ALB :80
   |
   v
Private EC2 :8000
   |
   v
FastAPI
```

The ALB:

* Runs in two public subnets
* Listens on HTTP port `80`
* Forwards traffic to the private EC2 instance on port `8000`
* Uses `/health` as the target health-check endpoint

The target was successfully validated as healthy during deployment testing.

---

# Private EC2

The application runs on a private EC2 instance.

The instance:

* Runs Amazon Linux
* Uses `t3.micro`
* Has no public IP
* Runs Docker
* Runs the FastAPI application
* Uses an IAM instance profile
* Is managed using AWS Systems Manager

The EC2 security group allows application traffic on port `8000` only from the ALB security group.

```text
ALB Security Group
        |
        | TCP 8000
        v
Private EC2 Security Group
```

This avoids exposing the application port directly to the Internet.

---

# Docker Application

The backend application is a FastAPI service packaged as a Docker image.

The application exposes:

```text
GET /health
```

Example response:

```json
{
  "status": "healthy",
  "service": "cloud-provisioner-api"
}
```

The Docker image was built through the GitHub Actions workflow and pushed to Amazon ECR.

The image was then pulled from ECR by the private EC2 instance and started as a Docker container.

---

# Amazon ECR

The project uses Amazon Elastic Container Registry as the container image registry.

```text
GitHub Actions
      |
      v
Docker Build
      |
      v
Amazon ECR
      |
      v
Private EC2
      |
      v
Docker Container
```

The ECR repository is Terraform-managed.

The repository uses immutable image tags and image scanning on push.

---

# VPC Endpoints

The private EC2 instance does not use a NAT Gateway.

Instead, VPC endpoints provide private connectivity to AWS services required by the instance.

Configured endpoints include:

### Interface endpoints

```text
com.amazonaws.us-east-1.ssm
com.amazonaws.us-east-1.ssmmessages
com.amazonaws.us-east-1.ec2messages
com.amazonaws.us-east-1.ecr.api
com.amazonaws.us-east-1.ecr.dkr
```

### Gateway endpoint

```text
com.amazonaws.us-east-1.s3
```

This allows the private instance to communicate with AWS services without requiring direct Internet connectivity.

---

# Why No NAT Gateway?

A NAT Gateway was initially considered for private-subnet Internet access.

It was intentionally removed from the final configuration because:

* NAT Gateway introduces ongoing AWS charges
* The project is intended for learning and portfolio use
* The required AWS service communication can be handled through VPC endpoints
* Docker Hub access is not required for the final deployment flow

The final architecture therefore uses:

```text
Private EC2
    |
    +-- SSM VPC Endpoints
    |
    +-- ECR VPC Endpoints
    |
    +-- S3 Gateway Endpoint
```

instead of:

```text
Private EC2
    |
    v
NAT Gateway
    |
    v
Internet
```

This was both a cost-management and architecture decision.

---

# AWS Systems Manager

AWS Systems Manager Session Manager is used to manage the private EC2 instance.

The instance receives an IAM role containing the required Systems Manager permissions.

Management flow:

```text
Developer
    |
    v
AWS CLI
    |
    v
SSM Session Manager
    |
    v
Private EC2
```

No public SSH access is required.

During validation, an SSM session was successfully established with the private EC2 instance.

---

# IAM Architecture

IAM permissions are separated according to workload responsibilities.

```text
GitHub Actions
      |
      v
GitHub OIDC
      |
      v
AWS IAM Role
      |
      v
ECR Operations


Private EC2
      |
      v
EC2 IAM Role
      |
      +-- Systems Manager
      |
      +-- ECR Image Pull
```

The EC2 instance does not store static AWS access keys.

GitHub Actions also does not require long-lived AWS access keys for the ECR workflow.

---

# GitHub OIDC

GitHub Actions authenticates with AWS using OpenID Connect.

Authentication flow:

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
      | AssumeRoleWithWebIdentity
      v
IAM Role
      |
      v
Temporary AWS Credentials
```

The IAM trust policy restricts which GitHub repository and branch/environment can assume the role.

The project used the following IAM role:

```text
GitHubActions-ECR-CloudProvisioner
```

The OIDC configuration was tested by generating a GitHub OIDC token, assuming the AWS IAM role, authenticating with ECR, and pushing a Docker image.

---

# Why GitHub OIDC?

Long-lived AWS access keys were intentionally avoided.

Instead, GitHub Actions receives temporary AWS credentials through OIDC.

Benefits include:

* No long-lived AWS access keys in GitHub
* Temporary credentials
* IAM-controlled trust relationship
* Repository/branch restrictions
* Short-lived authentication
* Clear separation between GitHub and AWS identity

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
|       +-- terraform.tfvars.example
|
+-- modules/
    |
    +-- alb/
    |
    +-- ec2/
    |
    +-- ecr/
    |
    +-- github_ecr/
    |
    +-- iam/
    |
    +-- private_ec2/
    |
    +-- ssm/
    |
    +-- vpc/
    |
    +-- vpc_endpoints/
```

---

# Module Responsibilities

## VPC Module

Responsible for:

* VPC
* Public subnet
* Second public subnet
* Private subnet
* Internet Gateway
* Public route table
* Private route table
* Route associations

---

## Private EC2 Module

Responsible for:

* Private EC2 instance
* Private EC2 security group
* AMI selection
* Instance profile association
* Application port configuration

---

## SSM Module

Responsible for:

* EC2 SSM IAM role
* Instance profile
* Systems Manager permissions
* ECR image-pull permissions

---

## VPC Endpoints Module

Responsible for:

* SSM endpoint
* SSM Messages endpoint
* EC2 Messages endpoint
* ECR API endpoint
* ECR Docker endpoint
* S3 gateway endpoint

---

## ALB Module

Responsible for:

* Application Load Balancer
* ALB security group
* Target group
* Target attachment
* HTTP listener
* Health checks

---

## ECR Module

Responsible for:

* ECR repository
* Repository configuration
* Image scanning
* Image tag mutability

---

## GitHub ECR Module

Responsible for:

* GitHub Actions IAM role
* GitHub OIDC trust relationship
* ECR-related deployment permissions

---

# Repository Structure

```text
cloud-infrastructure-provisioner/
|
+-- .github/
|   |
|   +-- workflows/
|       |
|       +-- backend.yml
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
|       +-- alb/
|       +-- ec2/
|       +-- ecr/
|       +-- github_ecr/
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

# CI/CD Workflow

The GitHub Actions workflow is located at:

```text
.github/workflows/backend.yml
```

The workflow handles backend validation, testing, Docker image creation, and ECR publishing.

## Pull Request Flow

```text
Pull Request
      |
      v
Checkout
      |
      v
Python Setup
      |
      v
Install Dependencies
      |
      v
Run Tests
      |
      v
Docker Build
```

The pull request workflow validates the application before changes are merged.

---

## Main Branch Flow

When code is pushed to `main`:

```text
Push to main
      |
      v
Checkout
      |
      v
Python Setup
      |
      v
Install Dependencies
      |
      v
Run Tests
      |
      v
Docker Build
      |
      v
GitHub OIDC
      |
      v
AWS IAM Role
      |
      v
Amazon ECR Login
      |
      v
Tag Docker Image
      |
      v
Push Image to ECR
```

The Docker image is tagged using the Git commit SHA.

This provides an immutable reference between a Git commit and the container image deployed from it.

---

# Deployment Flow

The validated application deployment followed this process:

```text
Developer
    |
    v
GitHub
    |
    v
GitHub Actions
    |
    +-- Tests
    |
    +-- Docker Build
    |
    +-- OIDC Authentication
    |
    v
Amazon ECR
    |
    v
Private EC2
    |
    v
Docker Container
    |
    v
FastAPI :8000
    |
    v
Application Load Balancer :80
    |
    v
Internet
```

The private EC2 instance successfully authenticated with ECR, pulled the application image, started the Docker container, and served the FastAPI health endpoint.

The ALB then successfully returned the application's health response externally.

---

# Terraform Remote State

Terraform uses Amazon S3 for remote state.

```text
S3 Bucket:
shikhar-cloud-provisioner-tfstate-2026
```

Backend configuration:

```text
Bucket:
shikhar-cloud-provisioner-tfstate-2026

Key:
cloud-infrastructure-provisioner/dev/terraform.tfstate

Region:
us-east-1
```

Remote state provides:

* Centralized state storage
* Persistence between Terraform executions
* CI/CD compatibility
* State sharing between environments/tools
* Protection against committing `terraform.tfstate` to Git

Terraform state files are excluded from Git using `.gitignore`.

The backend bucket is maintained separately from the infrastructure resources managed by the Terraform configuration.

---

# Security Design

The project demonstrates several security principles.

## Private Application Host

The application EC2 instance does not have a public IP.

```text
Internet
   |
   v
ALB
   |
   v
Private EC2
```

---

## Security Groups

The private EC2 security group allows application traffic only from the ALB security group.

```text
ALB SG
 |
 | TCP 8000
 v
Private EC2 SG
```

The application port is therefore not directly exposed to the Internet.

---

## IAM Roles

AWS credentials are not hard-coded into EC2 or application configuration.

IAM roles are used through instance profiles.

---

## GitHub OIDC

GitHub Actions uses temporary AWS credentials rather than long-lived AWS access keys.

---

## Systems Manager

The private EC2 instance is managed through Session Manager instead of public SSH access.

---

## VPC Endpoints

Private connectivity to AWS services is provided through VPC endpoints.

---

# Important Design Decisions

## Why Private EC2?

The application host does not need to be directly accessible from the Internet.

Putting the EC2 instance in a private subnet provides:

* Reduced public exposure
* ALB-based application access
* Security-group separation
* SSM-based administration

---

## Why ALB?

The ALB provides a controlled public entry point.

It separates:

```text
Internet-facing traffic
```

from:

```text
Private application infrastructure
```

It also provides health checking and creates a foundation for future horizontal scaling.

---

## Why Two Public Subnets?

AWS requires an Application Load Balancer to use subnets across at least two Availability Zones.

Therefore the project uses:

```text
us-east-1a
us-east-1b
```

for the ALB.

---

## Why VPC Endpoints Instead of NAT?

The project does not require general Internet access from the private EC2 instance.

VPC endpoints provide private connectivity to the AWS services required for:

* Systems Manager
* ECR
* S3

This avoids the recurring cost of a NAT Gateway for this learning environment.

---

## Why OIDC?

OIDC removes the need to store long-lived AWS access keys in GitHub Actions.

GitHub obtains temporary credentials through AWS STS after satisfying the IAM trust policy.

---

# Terraform Lifecycle

The complete infrastructure lifecycle was tested using Terraform.

```text
terraform init
      |
      v
terraform validate
      |
      v
terraform plan
      |
      v
terraform apply
      |
      v
AWS Infrastructure
      |
      v
Application Deployment
      |
      v
terraform destroy
```

The infrastructure was successfully destroyed after validation.

A subsequent Terraform plan showed that the infrastructure could be recreated from the Terraform configuration.

This demonstrates reproducible Infrastructure as Code rather than infrastructure that exists only through manual AWS Console configuration.

---

# Validation Performed

The project was validated at multiple layers.

## Terraform

```powershell
terraform fmt -recursive
terraform validate
terraform plan
terraform plan -destroy
```

Terraform validation completed successfully.

---

## GitHub Actions

The workflow was successfully tested for:

* Python dependency installation
* Automated tests
* Docker image build
* GitHub OIDC authentication
* AWS role assumption
* ECR authentication
* ECR image push

---

## AWS Systems Manager

The private EC2 instance was successfully accessed using:

```powershell
aws ssm start-session --target <instance-id> --region us-east-1
```

---

## Docker

The application image was successfully:

```text
Built
  |
  v
Pushed to ECR
  |
  v
Pulled by private EC2
  |
  v
Started as Docker container
```

---

## Application Health Check

Inside the private EC2 instance:

```text
GET http://localhost:8000/health
```

returned:

```json
{
  "status": "healthy",
  "service": "cloud-provisioner-api"
}
```

---

## ALB Validation

The Application Load Balancer target was healthy.

An external request to:

```text
http://<alb-dns-name>/health
```

returned HTTP `200` with the expected FastAPI health response.

This validated the complete path:

```text
Internet
   |
   v
ALB
   |
   v
Private EC2
   |
   v
Docker
   |
   v
FastAPI
```

---

# Challenges Solved

## 1. Private EC2 AMI Selection

An earlier AMI selection approach used a broad AMI filter that selected an unsuitable AWS image.

The resulting instance did not successfully register with Systems Manager.

The configuration was changed to use the AWS-managed Systems Manager parameter:

```text
/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64
```

This provided a predictable Amazon Linux AMI suitable for the project.

---

## 2. Private EC2 Connectivity

The private instance initially required a way to communicate with AWS services without public Internet access.

The final architecture uses VPC endpoints for:

```text
SSM
SSM Messages
EC2 Messages
ECR API
ECR Docker
S3
```

---

## 3. GitHub OIDC Trust Policy

The GitHub OIDC configuration required the AWS IAM trust policy to match the actual GitHub token subject.

The OIDC token claims were inspected and the trust relationship was corrected.

This provided hands-on experience with:

* GitHub OIDC
* IAM trust policies
* OIDC claims
* AWS STS
* `AssumeRoleWithWebIdentity`

---

## 4. AWS IAM Permissions

Terraform encountered AWS authorization failures while creating resources.

The required permissions were identified from AWS errors and added to the dedicated deployment role.

Examples included:

```text
iam:CreateRole
iam:TagRole
iam:CreateInstanceProfile
iam:AddRoleToInstanceProfile
```

This demonstrated how Terraform operations map to underlying AWS API permissions.

Further IAM permission tightening remains an improvement area.

---

## 5. Application Load Balancer Availability Zones

The initial ALB configuration used only one subnet.

AWS requires an Application Load Balancer to span at least two Availability Zones.

A second public subnet was therefore added:

```text
Public Subnet 1
us-east-1a

Public Subnet 2
us-east-1b
```

---

## 6. ECR Repository Cleanup

Terraform destroy initially could not remove the ECR repository because it still contained a Docker image.

The image was removed and the ECR repository was then deleted successfully.

This demonstrated an important Infrastructure-as-Code lifecycle consideration:

```text
Terraform resource dependency
          +
Resource contents
          |
          v
Destroy order matters
```

---

# Cost Management

AWS cost was considered throughout the project.

The following decisions were made specifically to keep the learning environment inexpensive:

* NAT Gateway was removed
* NAT Gateway Elastic IP was removed
* Private connectivity uses VPC endpoints where appropriate
* EC2 instances use small instance types
* Infrastructure was destroyed after validation
* ECR resources were cleaned up after testing

The Terraform S3 backend remains separately because it stores the Terraform state.

---

# Project Status

| Component                       | Status                             |
| ------------------------------- | ---------------------------------- |
| Terraform Infrastructure        | ✅                                  |
| Terraform Modules               | ✅                                  |
| AWS VPC                         | ✅                                  |
| Public Subnets                  | ✅                                  |
| Private Subnet                  | ✅                                  |
| Private EC2                     | ✅                                  |
| IAM                             | ✅                                  |
| AWS Systems Manager             | ✅                                  |
| VPC Interface Endpoints         | ✅                                  |
| S3 Gateway Endpoint             | ✅                                  |
| S3 Remote Terraform State       | ✅                                  |
| Amazon ECR                      | ✅                                  |
| Docker Application              | ✅                                  |
| Application Load Balancer       | ✅                                  |
| GitHub Actions                  | ✅                                  |
| GitHub OIDC                     | ✅                                  |
| Docker Image Push               | ✅                                  |
| Private EC2 ECR Pull            | ✅                                  |
| ALB Health Check                | ✅                                  |
| External Application Validation | ✅                                  |
| Terraform Destroy               | ✅                                  |
| CloudWatch Monitoring           | Planned                            |
| Automated Infrastructure Tests  | Planned                            |
| IAM Least-Privilege Refinement  | Planned                            |
| Infrastructure Drift Detection  | Planned                            |
| Production Monitoring/Alerting  | Planned                            |
| Kubernetes/ECS Deployment       | Not part of current implementation |

> **Current AWS state:** The project infrastructure used for validation has been destroyed with Terraform. The Terraform configuration remains capable of recreating the environment.

---

# Future Improvements

Possible future improvements include:

* CloudWatch application and infrastructure logging
* CloudWatch alarms
* Cost monitoring and budget alerts
* Automated Terraform infrastructure tests
* More granular IAM resource-level permissions
* Infrastructure drift detection
* Multiple Terraform environments
* Automated application deployment directly from CI/CD
* Blue/green or rolling deployment strategy
* Auto Scaling Group
* HTTPS using ACM
* Route 53 integration
* ECS deployment
* Kubernetes deployment

These are intentionally outside the current implementation.

---

# Local Setup

## Prerequisites

Install:

* Terraform
* AWS CLI
* Git
* Docker
* Python
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

Verify Docker:

```powershell
docker --version
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

# Configure Variables

Create a local variables file from the example:

### Windows

```powershell
copy terraform.tfvars.example terraform.tfvars
```

### Linux/macOS

```bash
cp terraform.tfvars.example terraform.tfvars
```

Update the values if required.

The actual `terraform.tfvars` file should not be committed to Git.

---

# Format Terraform

```powershell
terraform fmt -recursive
```

Check formatting without modifying files:

```powershell
terraform fmt -check -recursive
```

---

# Validate Terraform

```powershell
terraform validate
```

---

# Review Infrastructure Changes

```powershell
terraform plan
```

Review the resources Terraform intends to create or modify before applying.

---

# Deploy Infrastructure

```powershell
terraform apply
```

Review the proposed changes and confirm when appropriate.

---

# Destroy Infrastructure

When the environment is no longer required:

```powershell
terraform destroy
```

Review the destruction plan carefully before confirming.

The S3 backend should be treated separately because it stores Terraform state.

---

# Learning Outcomes

This project provided hands-on experience with:

* Infrastructure as Code
* Terraform modules
* Terraform state management
* AWS VPC
* CIDR addressing
* Public and private subnets
* Route tables
* Internet Gateway
* Security groups
* EC2
* IAM roles
* IAM policies
* IAM instance profiles
* AWS Systems Manager
* VPC endpoints
* Amazon ECR
* Docker
* Application Load Balancer
* GitHub Actions
* GitHub OIDC
* AWS STS
* IAM trust policies
* Temporary AWS credentials
* CI/CD workflows
* AWS troubleshooting
* Infrastructure lifecycle management
* AWS cost management

---

# Key Takeaways

The main architectural lessons from this project were:

```text
Public infrastructure
        |
        v
Application Load Balancer
        |
        v
Private applicatio
