# Backend Bootstrap

This directory contains Terraform configurations to create the S3 buckets and DynamoDB tables used for storing Terraform state for all environments.

## Prerequisites

- AWS credentials configured with permissions to create S3 buckets and DynamoDB tables
- Terraform >= 1.0

## Usage

Run this **once** before deploying any environment-specific infrastructure:

```bash
cd backend-bootstrap
terraform init
terraform apply
```

This will create:
- **us-east-1**: S3 bucket `sports-cards-terraform-state-bucket` and DynamoDB table `sports-cards-terraform-locks`
- **us-west-2**: S3 bucket `sports-cards-terraform-state-bucket-us-west-2` and DynamoDB table `sports-cards-terraform-locks-us-west-2`

## State Storage

This bootstrap configuration uses **local state** since the remote state infrastructure doesn't exist yet. The local state file (`terraform.tfstate`) should be:
- Committed to version control, OR
- Backed up securely

Once created, all environment-specific configurations will use these remote backends for their state storage.
