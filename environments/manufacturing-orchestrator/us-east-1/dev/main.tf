terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "sports-cards-terraform-state-bucket"
    key            = "manufacturing-orchestrator/us-east-1/dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "sports-cards-terraform-locks"
  }
}

locals {
  common_tags = {
    Environment = var.environment
    CostCode    = var.cost_code
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      ManagedBy   = "terraform"
      Environment = var.environment
      Service     = "manufacturing-orchestrator"
    }
  }
}

# ECS API Service
module "api_service" {
  source = "../../../../modules/ecs-api"

  project_name     = var.project_name
  environment      = var.environment
  aws_region       = var.aws_region
  vpc_id           = var.vpc_id
  subnet_ids       = var.subnet_ids
  container_image  = var.api_container_image
  container_port   = var.api_container_port
  task_cpu         = var.api_task_cpu
  task_memory      = var.api_task_memory
  desired_count    = var.api_desired_count
  assign_public_ip = var.assign_public_ip

  # Allow Lambda functions and workers to access API
  allowed_security_group_ids = [
    module.card_processor_lambda.security_group_id,
    module.user_service_lambda.security_group_id,
    module.data_sync_worker.security_group_id,
    module.image_processor_worker.security_group_id,
  ]

  environment_variables = [
    {
      name  = "ENV"
      value = var.environment
    },
    {
      name  = "LOG_LEVEL"
      value = "debug"
    },
    {
      name  = "API_VERSION"
      value = "v1"
    }
  ]

  tags = local.common_tags
}

# Lambda Microservices
module "card_processor_lambda" {
  source = "../../../../modules/lambda-microservice"

  project_name        = var.project_name
  environment         = var.environment
  service_name        = "card-processor"
  vpc_id              = var.vpc_id
  subnet_ids          = var.subnet_ids
  lambda_package_path = var.card_processor_package_path
  handler             = "index.handler"
  runtime             = "nodejs18.x"
  timeout             = 30
  memory_size         = 512

  environment_variables = {
    ENV       = var.environment
    LOG_LEVEL = "debug"
  }

  enable_function_url = true
  function_url_auth_type = "NONE"

  tags = local.common_tags
}

module "user_service_lambda" {
  source = "../../../../modules/lambda-microservice"

  project_name        = var.project_name
  environment         = var.environment
  service_name        = "user-service"
  vpc_id              = var.vpc_id
  subnet_ids          = var.subnet_ids
  lambda_package_path = var.user_service_package_path
  handler             = "index.handler"
  runtime             = "python3.11"
  timeout             = 15
  memory_size         = 256

  environment_variables = {
    ENV       = var.environment
    LOG_LEVEL = "info"
  }

  tags = local.common_tags
}

# ECS Worker Services
module "data_sync_worker" {
  source = "../../../../modules/ecs-worker"

  project_name     = var.project_name
  environment      = var.environment
  worker_name      = "data-sync"
  aws_region       = var.aws_region
  vpc_id           = var.vpc_id
  subnet_ids       = var.subnet_ids
  container_image  = var.data_sync_container_image
  task_cpu         = var.worker_task_cpu
  task_memory      = var.worker_task_memory
  desired_count    = var.data_sync_desired_count
  assign_public_ip = var.assign_public_ip
  create_sqs_queue = true

  environment_variables = [
    {
      name  = "ENV"
      value = var.environment
    },
    {
      name  = "SYNC_INTERVAL"
      value = "300"
    }
  ]

  tags = local.common_tags
}

module "image_processor_worker" {
  source = "../../../../modules/ecs-worker"

  project_name     = var.project_name
  environment      = var.environment
  worker_name      = "image-processor"
  aws_region       = var.aws_region
  vpc_id           = var.vpc_id
  subnet_ids       = var.subnet_ids
  container_image  = var.image_processor_container_image
  task_cpu         = "512"
  task_memory      = "1024"
  desired_count    = 2
  assign_public_ip = var.assign_public_ip
  create_sqs_queue = true

  environment_variables = [
    {
      name  = "ENV"
      value = var.environment
    },
    {
      name  = "MAX_IMAGE_SIZE"
      value = "10485760"
    }
  ]

  tags = local.common_tags
}

# RDS Database
module "database" {
  source = "../../../../modules/rds-database"

  project_name              = var.project_name
  environment               = var.environment
  vpc_id                    = var.vpc_id
  subnet_ids                = var.subnet_ids
  database_name             = var.db_name
  master_username           = var.db_username
  master_password           = var.db_password
  instance_class            = var.db_instance_class
  allocated_storage         = var.db_allocated_storage
  multi_az                  = false
  skip_final_snapshot       = true
  deletion_protection       = false
  # Allow access from API, Lambda functions, and workers
  allowed_security_groups   = [
    module.api_service.api_security_group_id,
    module.card_processor_lambda.security_group_id,
    module.user_service_lambda.security_group_id,
    module.data_sync_worker.security_group_id,
    module.image_processor_worker.security_group_id,
  ]

  tags = local.common_tags
}

# SQS Queue
module "notifications_queue" {
  source = "../../../../modules/sqs-queue"

  project_name              = var.project_name
  environment               = var.environment
  queue_name                = "notifications"
  visibility_timeout_seconds = 60
  create_alarms             = false

  tags = local.common_tags
}

# CloudWatch Rules
module "daily_cleanup_rule" {
  source = "../../../../modules/cloudwatch-rule"

  project_name        = var.project_name
  environment         = var.environment
  rule_name           = "daily-cleanup"
  rule_description    = "Trigger daily cleanup tasks"
  schedule_expression = "cron(0 2 * * ? *)"
  target_lambda_arn   = module.card_processor_lambda.function_arn

  tags = local.common_tags
}

module "hourly_sync_rule" {
  source = "../../../../modules/cloudwatch-rule"

  project_name        = var.project_name
  environment         = var.environment
  rule_name           = "hourly-sync"
  rule_description    = "Trigger hourly data sync"
  schedule_expression = "rate(1 hour)"
  target_sqs_queue_arn = module.data_sync_worker.queue_arn

  tags = local.common_tags
}


# IAM Resources
module "iam" {
  source = "../../../../modules/iam"

  project_name = var.project_name
  environment  = var.environment

  # Application Users
  iam_users = {
    app-deployer = {
      policies = [
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser",
      ]
    }
    app-reader = {
      policies = [
        "arn:aws:iam::aws:policy/ReadOnlyAccess",
      ]
    }
  }

  # Application Groups
  iam_groups = {
    developers = {
      policies = [
        "arn:aws:iam::aws:policy/PowerUserAccess",
      ]
      members = ["app-deployer", "app-reader"]
    }
  }

  # Service Roles
  iam_roles = {
    ci-cd-role = {
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Effect = "Allow"
          Principal = {
            Service = "codebuild.amazonaws.com"
          }
          Action = "sts:AssumeRole"
        }]
      })
      policies = [
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser",
        "arn:aws:iam::aws:policy/AmazonECS_FullAccess",
      ]
    }
  }

  # Custom Policies
  custom_policies = {
    s3-data-access = {
      description = "Access to S3 data buckets"
      policy_json = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "s3:GetObject",
              "s3:PutObject",
              "s3:ListBucket"
            ]
            Resource = [
              "arn:aws:s3:::${var.project_name}-${var.environment}-data/*",
              "arn:aws:s3:::${var.project_name}-${var.environment}-data"
            ]
          }
        ]
      })
    }
  }

  tags = local.common_tags
}
