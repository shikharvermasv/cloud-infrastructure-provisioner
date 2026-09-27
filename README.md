# Cloud Infrastructure Provisioner

Infrastructure-as-Code project for provisioning and managing AWS cloud infrastructure using **Terraform**.

The project demonstrates a modular AWS architecture with public and private EC2 instances, IAM roles, private networking, AWS Systems Manager (SSM), VPC Interface Endpoints, and remote Terraform state management.

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

              AWS VPC: 10.0.0.0/16
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
                     HTTPS / 443
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

### Final private EC2 access design

The private EC2 instance does **not** have a public IP address.

Instead, it is managed through **AWS Systems Manager Session Manager** using VPC Interface Endpoints.

This allows administrative access without:

* Public IP addresses
* SSH access from the internet
* A NAT Gateway in the final architecture
* Managing SSH key pairs for the private instance

The setup was tested end-to-end using:

```text
Developer machine
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
* Terraform state locking using S3 lockfile
* Environment-based Terraform structure
* Resource tagging

---

## Project Structure

```text
cloud-infrastructure-provisioner/
│
├── README.md
├── .gitignore
│
└── terraform/
    │
    ├── environment/
    │   └── dev/
    │       ├── .terraform.lock.hcl
    │       ├── main.tf
    │       ├── outputs.tf
    │       └── variables.tf
    │
    └── modules/
        ├── ec2/
        │   ├── main.tf
        │   ├── outputs.tf
        │   └── variables.tf
        │
        ├── iam/
        │   ├── main.tf
        │   ├── outputs.tf
        │   └── variables.tf
        │
        ├── private_ec2/
        │   ├── main.tf
        │   ├── outputs.tf
        │   └── variables.tf
        │
        ├── ssm/
        │   ├── main.tf
        │   ├── outputs.tf
        │   └── variables.tf
        │
        ├── vpc/
```
