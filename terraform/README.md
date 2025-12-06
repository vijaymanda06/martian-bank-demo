# Martian Bank Terraform Infrastructure

This directory contains Terraform configurations for provisioning the Martian Bank infrastructure on AWS.

## Structure

```
terraform/
├── main.tf                 # Root module orchestration
├── variables.tf            # Input variables
├── outputs.tf              # Output values
├── providers.tf            # Provider configuration
├── backend.tf              # S3 backend configuration
├── modules/
│   ├── vpc/               # VPC, subnets, NAT gateways
│   ├── eks/               # EKS cluster with Auto Mode
│   ├── iam/               # IAM roles, policies, OIDC
│   └── secrets/           # Secrets Manager resources
└── environments/
    ├── dev.tfvars         # Development environment
    └── prod.tfvars        # Production environment
```

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform >= 1.5.0
3. S3 bucket and DynamoDB table for state management

### Create Backend Resources

```bash
# Create S3 bucket for state
aws s3api create-bucket --bucket martianbank-terraform-state --region us-west-2 \
  --create-bucket-configuration LocationConstraint=us-west-2

# Enable versioning
aws s3api put-bucket-versioning --bucket martianbank-terraform-state \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for locking
aws dynamodb create-table --table-name martianbank-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

## Usage

### Initialize

```bash
terraform init
```

### Plan (Development)

```bash
terraform plan -var-file=environments/dev.tfvars
```

### Apply (Development)

```bash
terraform apply -var-file=environments/dev.tfvars
```

### Plan (Production)

```bash
terraform plan -var-file=environments/prod.tfvars
```

## Modules

### VPC Module
Creates networking infrastructure including:
- VPC with DNS support
- Public subnets for ALB
- Private subnets for EKS nodes
- Internet Gateway
- NAT Gateways

### EKS Module
Creates EKS cluster with Auto Mode:
- AWS-managed node pools
- Karpenter scaling
- IRSA enabled

### IAM Module
Creates IAM resources:
- GitHub OIDC provider
- GitHub Actions role
- External Secrets Operator role

### Secrets Module
Creates Secrets Manager resources:
- MongoDB credentials
- JWT configuration

## Sensitive Variables

Provide sensitive values via environment variables:

```bash
export TF_VAR_mongodb_uri="mongodb://..."
export TF_VAR_jwt_secret="your-secret-here"
```
