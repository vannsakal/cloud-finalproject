
# cloud-finalproject

A scalable, secure, and highly available web application deployed on AWS using
Terraform (Infrastructure as Code). Built for the Cloud Computing final project.

## Architecture

```
                         Internet
                            │
                     ┌──────▼──────┐
                     │     ALB      │  (public subnets, 2 AZs)
                     └──────┬──────┘
                            │
                ┌───────────┴───────────┐
                │                       │
        ┌───────▼───────┐       ┌───────▼───────┐
        │  EC2 (ASG)     │       │  EC2 (ASG)     │   private subnets, 2 AZs
        │  nginx         │  ...  │  nginx         │   min 2 / max 5 (t3.micro)
        └───────┬───────┘       └───────┬───────┘
                │                       │
          NAT Gateway (per AZ)  ─────►  Internet (outbound only)
                │
        ┌───────▼───────┐
        │   S3 Bucket    │  (encrypted, blocked from public access)
        └────────────────┘
```

- **VPC** with 2 public and 2 private subnets across two Availability Zones
- **Application Load Balancer (ALB)** in the public subnets, fronting the app
- **Auto Scaling Group (ASG)** running EC2 instances in the private subnets
  (no direct internet exposure — outbound traffic goes through NAT gateways)
- **IAM role** on each instance for AWS Systems Manager access (no SSH keys)
- **S3 bucket** with public access blocked and AES256 server-side encryption
- **CloudWatch** for metrics, log aggregation, alarms, and a dashboard

## Tech stack

| Layer                | Tool / Service |
|                      |
| IaC                  | Terraform |
| Compute              | EC2 (Amazon Linux), Auto Scaling Group |
| Networking           | VPC, public/private subnets, IGW, NAT Gateway |
| Load balancing       | Application Load Balancer |
| Storage              | S3 |
| Access control       | IAM (instance profile, least privilege) |
| Monitoring           | CloudWatch (metrics, logs, alarms, dashboard) |
| App                  | Python (Flask) + MySQL |
| Web server           | nginx |
| State management     | Terraform S3 backend with state locking |

## Project structure

```
cloud-finalproject/
├── main.tf                  # VPC, subnets, routing, NAT, ASG, launch template, S3 bucket
├── vars.tf                  # Input variables (region, CIDRs, instance sizing, etc.)
├── outputs.tf                # Terraform outputs (subnet IDs, SG IDs, S3 bucket info)
├── provider.tf               # AWS provider + default tags
├── backend.tf                 # Remote state (S3 backend with locking)
├── alb.tf                    # Application Load Balancer, listener, target group, ALB security group
├── asg_security_group.tf      # Security group for the ASG instances
├── iam.tf                     # IAM role + instance profile for SSM access
├── server_setup.sh            # EC2 user-data: installs and starts nginx
├── app.py                     # Flask CRUD app (message board) backed by MySQL
├── .gitignore                 # Excludes state files, secrets, and provider binaries
├── .terraform.lock.hcl        # Terraform provider version lock file
└── README.md
```

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.5
- An AWS account with credentials configured (`aws configure`)
- An existing S3 bucket for the Terraform state backend (see `backend.tf`)

## Deployment

```bash
git clone https://github.com/vannsakal/cloud-finalproject.git
cd cloud-finalproject

terraform init
terraform plan
terraform apply
```

Terraform will provision the VPC, ALB, ASG, S3 bucket, and IAM resources. Once
complete, check the outputs for the ALB DNS name to reach the app.

To tear everything down:

```bash
terraform destroy
```

## Key variables (`vars.tf`)

| Variable        | Description             | Default |

| `environment`   | Environment name        | `dev` |
| `aws_region`    | AWS region              | `ap-southeast-1` |
| `main_vpc_cidr` | VPC CIDR block          | `10.0.0.0/16` |
| `ami_id`        | AMI for EC2 instances   | Amazon Linux AMI |
| `instance_type` | EC2 instance type       | `t3.micro` |
| `bucket_name`   | S3 bucket name          | `cloud-finalproject-s3-bucket-2026` |
| `min_size` / `max_size` / `desired_capacity` | ASG sizing | `2` / `5` / `2` |

## High availability & scaling

- Instances are spread across two Availability Zones in private subnets.
- The ASG maintains a minimum of 2 instances and scales up to 5 based on demand.
- The ALB health-checks each instance and stops routing to any that fail,
  while the ASG replaces unhealthy instances automatically.

## Security

- App servers sit in private subnets with no public IPs; only the ALB is
  internet-facing.
- Security groups restrict inbound traffic to the ASG so it only accepts
  traffic from the ALB's security group.
- EC2 access is via AWS Systems Manager (IAM instance profile) — no SSH keys.
- The S3 bucket blocks all public access and encrypts objects at rest.

## Monitoring & logging

CloudWatch is used for:
- EC2 and ALB metrics (CPU utilization, request count, healthy/unhealthy hosts)
- Centralized nginx access/error logs
- Alarms for high CPU, unhealthy targets, and elevated 5xx error rates
- A dashboard summarizing the app's health

## Team

Maintained as a group project — see commit history for individual
contributions.