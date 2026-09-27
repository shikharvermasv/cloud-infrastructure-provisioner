# Cloud Infrastructure Provisioner

Infrastructure-as-Code project for provisioning AWS cloud infrastructure using **Terraform**.

This project demonstrates a modular AWS architecture with public and private EC2 instances, IAM roles, private networking, AWS Systems Manager (SSM), VPC Interface Endpoints, and remote Terraform state management.

---

## Architecture

```text
                         Internet
                            |
                            v
                    +----------------+
                    | Internet       |
                    | Gateway        |
                    +-------+--------+
                            |
                     Public Subnet
                      10.0.1.0/24
                            |
                            v
                    +----------------+
                    | Public EC2     |
                    | Amazon Linux   |
                    +----------------+

                 AWS VPC 10.0.0.0/16
                            |
                            |
                    Private Subnet
                     10.0.2.0/24
                            |
                            v
                    +----------------+
                    | Private EC2    |
                    | No Public IP   |
                    +-------+--------+
                            |
                         HTTPS 443
                            |
             +--------------+--------------+
             |              |              |
             v              v              v
          SSM Endpoint  SSMMessages    EC2Messages
             |              |              |
             +--------------+--------------+
                            |
                            v
                  AWS Systems Manager
                     Session Manager
                            |
                            v
                       Developer
```

### Final Private EC2 Access

The private EC2 instance does **not** have a public IP address.

It is managed through **AWS Systems Manager Session Manager** using VPC Interface Endpoints.

This avoids requiring:

* A public IP on the private EC2
* Internet-facing SSH access
* A NAT Gateway in the final architecture
* An SSH key pair for the private instance

The setup was tested end-to-end using:

```text
Developer Machine
       |
       v
AWS Systems Manager
       |
       v
Private EC2
10.0.2.136
```

---

## Features

* AWS VPC provisioning with Terraform
* Public and private subnets
* Internet Gateway
* Public and private route tables
* Public EC2 instance
* Private EC2 instance
* IAM roles and instance profiles
* S3 access policy for EC2
* AWS Systems Manager integration
* SSM VPC Interface Endpoints
* Security groups
* Terraform modules
* Terraform remote state in Amazon S3
* S3 state versioning
* Terraform state locking using the S3 lockfile mechanism
* Environment-based Terraform structure
* AWS resource tagging

---

## Project Structure

```text
cloud-infrastructure-provisioner/
|
├── README.md
├── .gitignore
|
└── terraform/
    |
    ├── environment/
    |   |
    |   └── dev/
    |       ├── .terraform.lock.hcl
    |       ├── main.tf
    |       ├── outputs.tf
    |       └── variables.tf
    |
    └── modules/
        |
        ├── ec2/
        |   ├── main.tf
        |   ├── outputs.tf
        |   └── variables.tf
        |
        ├── iam/
        |   ├── main.tf
        |   ├── outputs.tf
        |   └── variables.tf
        |
        ├── private_ec2/
        |   ├── main.tf
        |   ├── outputs.tf
        |   └── variables.tf
        |
        ├── ssm/
        |   ├── main.tf
        |   ├── outputs.tf
        |   └── variables.tf
        |
        ├── vpc/
        |   ├── main.tf
        |   ├── outputs.tf
        |   └── variables.tf
        |
        └── vpc_endpoints/
            ├── main.tf
            ├── outputs.tf
            └── variables.tf
```

---

## AWS Services Used

| Service                 | Purpose                                 |
| ----------------------- | --------------------------------------- |
| Amazon VPC              | Network isolation                       |
| Amazon EC2              | Compute instances                       |
| Amazon IAM              | Roles, policies and permissions         |
| Amazon S3               | Terraform remote state                  |
| AWS Systems Manager     | Private EC2 management                  |
| VPC Interface Endpoints | Private connectivity to SSM             |
| Internet Gateway        | Internet connectivity for public subnet |
| Security Groups         | Network-level access control            |

---

## Terraform Module Design

The infrastructure is divided into reusable Terraform modules.

### VPC

Creates:

* VPC
* Public subnet
* Private subnet
* Internet Gateway
* Public route table
* Private route table
* Route table associations

### EC2

Creates the public EC2 instance and its security group.

### Private EC2

Creates an EC2 instance inside the private subnet without a public IP address.

### IAM

Creates:

* EC2 IAM role
* IAM policy
* Instance profile
* Policy attachment

The current EC2 policy allows the instance to list S3 buckets.

### SSM

Creates the IAM role and instance profile required for AWS Systems Manager.

### VPC Endpoints

Creates Interface VPC Endpoints for:

* `ssm`
* `ssmmessages`
* `ec2messages`

These endpoints allow the private EC2 instance to communicate with AWS Systems Manager without requiring a NAT Gateway.

---

## Networking

### VPC

```text
CIDR: 10.0.0.0/16
```

### Public Subnet

```text
CIDR: 10.0.1.0/24
```

The public subnet has a route through the Internet Gateway.

### Private Subnet

```text
CIDR: 10.0.2.0/24
```

The private subnet does not have a default route to the internet in the final architecture.

The private EC2 instance communicates with AWS Systems Manager through VPC Interface Endpoints.

---

## Security Design

The project uses a private-by-default approach for the private EC2 instance.

### Private EC2

The private EC2 instance:

* Has no public IP
* Does not require an SSH key pair
* Is managed using Session Manager
* Communicates with SSM through private VPC endpoints

### Security Groups

The SSM endpoint security group allows HTTPS traffic:

```text
TCP 443
```

from the private EC2 security group.

This allows the private instance to communicate with the SSM endpoints.

---

## Remote Terraform State

Terraform state is stored remotely in Amazon S3.

The project uses:

* S3 remote backend
* S3 versioning
* Terraform state locking using the S3 lockfile mechanism

The state is stored using a key similar to:

```text
cloud-infrastructure-provisioner/dev/terraform.tfstate
```

Sensitive local Terraform files are excluded from Git using `.gitignore`.

Examples:

```text
terraform.tfstate
terraform.tfstate.backup
terraform.tfvars
```

---

## Deployment

### Prerequisites

Install:

* Terraform
* AWS CLI
* Git
* AWS Session Manager Plugin

Configure AWS credentials with the required permissions.

Verify AWS CLI:

```bash
aws sts get-caller-identity
```

Verify Terraform:

```bash
terraform version
```

---

### Initialize Terraform

Navigate to the development environment:

```bash
cd terraform/environment/dev
```

Initialize Terraform:

```bash
terraform init
```

---

### Review Infrastructure

Run:

```bash
terraform plan
```

Review the resources Terraform intends to create or modify.

---

### Apply Infrastructure

Run:

```bash
terraform apply
```

Review the plan and confirm the deployment when prompted.

---

### View Outputs

Run:

```bash
terraform output
```

Important outputs include:

```text
vpc_id
subnet_id
private_subnet_id
instance_id
private_instance_id
private_instance_ip
iam_role_arn
ssm_instance_profile_name
```

---

## Connect to the Private EC2

The private EC2 instance can be accessed using AWS Systems Manager Session Manager.

Example:

```bash
aws ssm start-session \
  --target <PRIVATE_INSTANCE_ID> \
  --region us-east-1
```

No SSH connection or public IP is required.

Example successful session:

```text
Starting session with SessionId: ...

sh-5.2$ hostname
ip-10-0-2-136.ec2.internal

sh-5.2$ exit
Exiting session...
```

---

## Validation

The private EC2 instance was validated using:

```bash
aws ssm describe-instance-information \
  --region us-east-1
```

The instance reported:

```text
PingStatus: Online
```

Network connectivity to the SSM endpoint was also tested.

DNS resolution successfully resolved the SSM service to a private VPC endpoint address.

HTTPS connectivity to the endpoint was successfully established over port 443.

---

## NAT Gateway Experiment

A NAT Gateway was temporarily deployed during development to understand and troubleshoot private subnet connectivity.

After validating the networking requirements, the NAT Gateway was removed to avoid unnecessary ongoing AWS charges.

The final architecture uses:

```text
Private EC2
     |
     v
VPC Interface Endpoints
     |
     v
AWS Systems Manager
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
     |
     v
AWS Systems Manager
```

---

## Troubleshooting Experience

During development, the private EC2 instance initially could not register with Systems Manager because the private subnet had no connectivity path to the required AWS endpoints.

The issue was investigated using:

* SSM agent logs
* DNS resolution tests
* HTTPS connectivity tests
* AWS CLI
* EC2 Instance Connect Endpoint for temporary diagnostics

The final solution was to configure private SSM VPC Interface Endpoints and verify:

```text
Private EC2
    |
    | TCP 443
    v
SSM VPC Endpoints
    |
    v
AWS Systems Manager
```

The private instance subsequently registered successfully and reported an **Online** SSM status.

---

## What I Learned

This project provided hands-on experience with:

* AWS VPC networking
* Public vs private subnets
* Route tables
* IAM roles and instance profiles
* Terraform module design
* Terraform variables and outputs
* Remote Terraform state
* S3 state versioning
* State locking
* EC2 networking
* Security groups
* AWS Systems Manager
* VPC Interface Endpoints
* Troubleshooting private network connectivity
* AWS CLI diagnostics
* Infrastructure lifecycle management
* AWS cost control

---

## Future Improvements

Planned improvements include:

* GitHub Actions CI/CD
* Automated Terraform formatting and validation
* Terraform security scanning
* Multiple environments such as `dev`, `staging`, and `prod`
* Containerized application deployment
* ECS or Kubernetes deployment
* Automated infrastructure testing
* Improved secrets management
* Monitoring and observability

---

## Technologies

```text
AWS
Terraform
AWS CLI
Linux
Git
GitHub
IAM
EC2
VPC
S3
SSM
Infrastructure as Code
```

---

## Author

**Shikhar Verma**

B.Tech Information Technology

Cloud / DevOps / Infrastructure Engineering

GitHub: [shikharvermasv](https://github.com/shikharvermasv)
