# Project Notes

## Overview

This project provides a comprehensive multi-region, multi-service, multi-environment Terraform infrastructure for a sports cards application platform. The infrastructure supports three microservices (card-catalog-api, orders-ingestion, manufacturing-orchestrator) across three environments (dev, staging, production) in two AWS regions (us-east-1 and us-west-2).

## What Was Created

### Infrastructure Components

**Compute Layer**:
- **ECS on EC2**: Container orchestration with Auto Scaling Groups (ASG) for both API services and workers
  - EC2 launch type (replaced Fargate for cost optimization)
  - Capacity providers with managed scaling
  - CloudWatch-based CPU autoscaling policies
  - Dynamic port mapping for load balancer integration
  - Configurable instance types and scaling parameters (min: 1, max: 10, desired: 2-5)
  
- **Lambda Functions**: Serverless microservices for background processing
  - VPC-integrated with security group isolation
  - Function URLs enabled for API gateway alternatives
  - Node.js 18 and Python 3.11 runtimes

**Data Layer**:
- **RDS PostgreSQL**: Managed relational database with high availability
  - Production: Multi-AZ with 2 same-region read replicas
  - Cross-region read replica (us-east-1 → us-west-2) for disaster recovery
  - Dev/Staging: Single-AZ for cost optimization
  - 30-day backup retention in production
  - Automated snapshots and deletion protection

**Messaging & Events**:
- **SQS Queues**: Asynchronous message processing with dead letter queues
  - 14-day message retention
  - Configurable visibility timeouts
  - CloudWatch alarms for queue depth and message age
  
- **EventBridge Rules**: Scheduled automation
  - Daily cleanup tasks (4 AM UTC)
  - Hourly data synchronization

**Security & IAM**:
- **Security Groups**: Network-level security with least-privilege access
  - ALB → ECS instances (dynamic ports 32768-65535)
  - API ← Lambda/Workers (port-specific ingress rules)
  - RDS ← API/Lambda/Workers (PostgreSQL port 5432)
  
- **IAM Resources**: Identity and access management
  - Application users (deployer, reader)
  - Service roles (CI/CD, ECS tasks, Lambda execution)
  - Custom policies (S3 data access)
  - Access keys stored encrypted in SSM Parameter Store

**Infrastructure as Code**:
- **7 Reusable Modules**: ecs-api, ecs-worker, lambda-microservice, rds-database, sqs-queue, cloudwatch-rule, iam
- **12 Environment Deployments**: 3 services × 3 SDLC environments + 3 services × 1 DR environment
- **Backend Bootstrap**: S3 state storage and DynamoDB locking in both regions

### Directory Structure

```
sports-cards-infrastructure-terraform/
├── backend-bootstrap/          # S3 + DynamoDB for state management
│   ├── main.tf                 # Provider configurations
│   ├── backend-us-east-1.tf    # us-east-1 backend resources
│   ├── backend-us-west-2.tf    # us-west-2 backend resources
│   └── README.md               # Bootstrap instructions
├── modules/                    # Reusable Terraform modules
│   ├── ecs-api/               # ECS EC2 API with ALB & autoscaling
│   ├── ecs-worker/            # ECS EC2 workers with autoscaling
│   ├── lambda-microservice/   # Lambda functions with VPC
│   ├── rds-database/          # RDS with replicas
│   ├── sqs-queue/             # SQS with DLQ
│   ├── cloudwatch-rule/       # EventBridge schedules
│   └── iam/                   # IAM management
├── environments/               # Environment-specific configs
│   ├── card-catalog-api/
│   │   ├── us-east-1/{dev,staging,prod}/
│   │   └── us-west-2/prod/
│   ├── orders-ingestion/
│   │   └── [same structure]
│   └── manufacturing-orchestrator/
│       └── [same structure]
├── ARCHITECTURE.md             # Deployment guide with security details
├── DIAGRAM.md                  # Full architecture diagram
└── NOTES.md                    # This file
```

## Resilience and Scaling Strategies

### High Availability
- **Multi-AZ RDS**: Production databases span multiple availability zones for automatic failover
- **Cross-Region Replication**: RDS read replicas in us-west-2 for disaster recovery
- **Hot Standby**: Full production stack deployed in us-west-2 for immediate failover capability
- **Auto Scaling**: ECS clusters automatically scale based on CPU utilization (75% up, 25% down)
- **Load Balancing**: Application Load Balancers distribute traffic across healthy ECS tasks

### Scaling Configuration
**ECS Auto Scaling**:
- ASG min: 1, max: 10, desired: 2-5 (configurable per environment)
- Capacity provider target: 100%
- Scaling step size: 1-10 instances
- CPU thresholds: 75% (scale up), 25% (scale down)
- Cooldown periods: 5 minutes

**RDS Scaling**:
- Vertical: Instance class configuration
- Horizontal: 2 read replicas per production environment
- Cross-region: 1 read replica for DR

### Disaster Recovery
- **Strategy**: Hot standby in us-west-2 with continuous cross-region replication
- **RTO/RPO**: Minimal - promote us-west-2 read replica to primary
- **Scope**: Production only (dev/staging single-region for cost optimization)

## Security and IAM Model

### Network Security
**Defense in Depth**:
1. **Internet → ALB**: Public access on port 80
2. **ALB → ECS Instances**: Dynamic ports (32768-65535), security group restricted
3. **ECS Tasks → RDS**: Port 5432, security group restricted
4. **Lambda/Workers → API**: Security group-based access control
5. **Components → RDS**: Security group-based access control

**Security Group Wiring**:
- Each module creates its own security groups
- Environment configs pass security group IDs between modules
- Dynamic ingress rules via `allowed_security_group_ids` and `allowed_security_groups` variables
- No hardcoded IP addresses or overly permissive rules

### IAM Model
**Least Privilege Approach**:
- **Execution Roles**: ECS task execution (pull images, write logs)
- **Task Roles**: Application-level permissions (database access, S3 operations)
- **Instance Roles**: EC2 instance permissions for ECS agent
- **Lambda Roles**: Function execution with VPC access when needed

**Per-Module IAM**:
- ECS API: Execution role, task role, instance role, instance profile
- ECS Worker: Same as API plus optional custom policies for SQS
- Lambda: Execution role with basic + VPC access policies

**Centralized IAM Module**:
- Application users and groups
- CI/CD service roles
- Custom policies (e.g., S3 data access)
- OIDC provider support for GitHub Actions

## Observability Standards

### Logging
**CloudWatch Logs**:
- ECS containers: 30-day retention (production), 7-day (dev/staging)
- Lambda functions: Automatic via AWS Lambda integration
- Log groups per service component
- Structured naming: `/ecs/{project}-{environment}-{service}`

### Monitoring
**CloudWatch Metrics**:
- ECS cluster and service metrics (CPU, memory, task count)
- RDS metrics (connections, replication lag, IOPS)
- SQS metrics (queue depth, message age)
- ALB metrics (target health, request count, latency)

**Alarms**:
- ECS CPU high/low for autoscaling triggers
- SQS queue depth thresholds (1000 messages)
- SQS message age thresholds (10 minutes)
- Customizable per environment via variables

### Container Insights
- Enabled on all ECS clusters
- Provides detailed metrics and logs at task/container level

## Cost Governance

### Tagging Strategy
All resources include:
- `Project`: sports-cards
- `ManagedBy`: terraform
- `Environment`: dev/staging/prod
- `Service`: service name (card-catalog-api, etc.)
- `CostCode`: 8-digit alphanumeric per environment for spend tracking

**Example Cost Codes**:
- card-catalog-api dev: `A1B2C3D4`
- orders-ingestion prod: `J9K0L1M2`
- manufacturing-orchestrator staging: `X7Y8Z9W0`

### Cost Optimization Decisions
**EC2 vs Fargate**:
- **Decision**: EC2 launch type for ECS
- **Rationale**: Lower cost for sustained workloads, better control over instance sizing
- **Trade-off**: More operational complexity vs. Fargate's simplicity

**Environment Tiering**:
- **Dev/Staging**: Single-AZ RDS, lower desired capacity, us-east-1 only
- **Production**: Multi-AZ RDS, read replicas, cross-region DR, higher capacity
- **Trade-off**: Cost vs. resilience

**Regional Strategy**:
- **us-east-1**: All environments (9 total)
- **us-west-2**: Production only (3 total)
- **Rationale**: DR for production, cost optimization for lower environments

### State Management Costs
- **S3 Storage**: Minimal for Terraform state files
- **DynamoDB**: On-demand billing for state locks
- **Regional Separation**: Separate backends in each region for compliance/latency

## Assumptions

### Pre-existing Infrastructure
- **AWS Account Setup**: Initial account configuration is complete
- **VPC and Networking**: VPCs, subnets, route tables, internet gateways, and NAT gateways already exist
- **Network Configuration**: Proper CIDR ranges and subnet allocation
- **DNS**: Route53 or equivalent DNS management in place
- **KMS Keys**: Encryption keys available for RDS and other encrypted resources

### Business Requirements
- **Hot Standby Desired**: Full production stack in secondary region for immediate failover
- **No DR for Non-Production**: Dev and staging environments are single-region to reduce costs
- **Cost Code Tracking**: Accounting has provided 8-digit alphanumeric cost codes for spend tracking
- **Service Ownership**: Three distinct microservices with separate teams/ownership

### Operational Model
- **Terraform Expertise**: Team has Terraform knowledge for infrastructure management
- **AWS Proficiency**: Team understands AWS services and best practices
- **CI/CD Pipeline**: Deployment automation exists or will be implemented
- **Monitoring Setup**: CloudWatch or equivalent monitoring solution in use

## Trade-offs

### Cost vs. Resilience
**Decision: Tiered Approach**
- Production: Maximum resilience (Multi-AZ, read replicas, cross-region DR)
- Staging: Moderate resilience (single-AZ, no DR)
- Dev: Minimal resilience (single-AZ, no DR, lower capacity)

**Impact**:
- ✅ Optimizes costs for lower environments
- ✅ Appropriate risk mitigation for production
- ❌ Dev/staging cannot test full DR scenarios

### EC2 vs. Fargate
**Decision: EC2 Launch Type**
- Lower ongoing costs for sustained workloads
- Better resource utilization with Auto Scaling
- More control over instance types and sizing

**Impact**:
- ✅ Cost savings of ~30-40% vs. Fargate
- ✅ More control and flexibility
- ❌ More operational overhead (patching, scaling configuration)
- ❌ Slightly slower scaling compared to Fargate

### Modular vs. Monolithic
**Decision: Highly Modular (7 modules)**
- Reusable components across services
- Consistent patterns and best practices
- Easier maintenance and updates

**Impact**:
- ✅ DRY principle - no code duplication
- ✅ Easier to add new services
- ❌ Slightly more complex initial setup
- ❌ Module dependencies must be managed carefully

### Security Group Approach
**Decision: Module-Created Security Groups**
- Each module creates its own security groups
- Environment configs wire them together via outputs

**Impact**:
- ✅ Clear ownership and encapsulation
- ✅ Easy to understand component boundaries
- ❌ Cannot use shared security groups across stacks
- ❌ More security groups to manage (7 per environment)

## Future Enhancements

### Dynamic Infrastructure Discovery
**Current State**: Hard-coded values for VPC IDs, subnet IDs, AMI IDs, etc.

**Enhancement**: Replace with data sources
```hcl
data "aws_vpc" "main" {
  tags = {
    Name = "sports-cards-${var.environment}"
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  tags = {
    Tier = "private"
  }
}

data "aws_ami" "ecs_optimized" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}
```

**Benefits**:
- Automatically adapt to infrastructure changes
- Follow organizational naming conventions
- Reduce manual configuration
- Enable dynamic multi-account deployments

### Additional Potential Enhancements

1. **WAF Integration**
   - Add AWS WAF to ALBs for application-level protection
   - Rate limiting and geo-blocking rules

2. **Enhanced Monitoring**
   - X-Ray tracing for distributed request tracking
   - Custom CloudWatch dashboards per service
   - PagerDuty/Opsgenie integration for alerting

3. **Secrets Management**
   - Migrate from variables to AWS Secrets Manager
   - Automatic rotation for database credentials
   - Integration with HashiCorp Vault

4. **CI/CD Pipeline**
   - GitHub Actions workflows for terraform plan/apply
   - Automated testing with terraform validate and tflint
   - Environment promotion strategy (dev → staging → prod)

5. **Cost Optimization**
   - Reserved Instances for predictable workloads
   - Savings Plans for long-term commitments
   - Automated rightsizing recommendations

6. **Service Mesh**
   - AWS App Mesh for advanced traffic management
   - Circuit breakers and retry policies
   - Mutual TLS between services

7. **Multi-Account Strategy**
   - Separate AWS accounts per environment
   - AWS Organizations with consolidated billing
   - Cross-account IAM roles

8. **Database Enhancements**
   - RDS Proxy for connection pooling
   - Performance Insights enabled
   - Automated backup verification

## Deployment Instructions

### Prerequisites
1. AWS credentials configured with appropriate permissions
2. Terraform >= 1.0 installed
3. tflint installed (optional but recommended)

### Bootstrap Process
```bash
# 1. Create backend infrastructure
cd backend-bootstrap/
terraform init
terraform apply

# 2. Deploy an environment
cd ../environments/card-catalog-api/us-east-1/dev/
terraform init
terraform plan
terraform apply
```

### Deployment Order
1. Backend bootstrap (once)
2. Dev environments (test configurations)
3. Staging environments (pre-production validation)
4. Production us-east-1 (primary region)
5. Production us-west-2 (DR region)

## Additional Documentation

- **[ARCHITECTURE.md](ARCHITECTURE.md)**: Detailed deployment guide with module composition, security group configuration, and IAM setup
- **[DIAGRAM.md](DIAGRAM.md)**: Full architecture diagram with all components and environments
- **[backend-bootstrap/README.md](backend-bootstrap/README.md)**: Instructions for bootstrapping state storage infrastructure

## AI Usage

**AI Assistant**: Warp Dev  
**Model**: Claude 3.7 Sonnet  
**Credits Used**: 595 credits
