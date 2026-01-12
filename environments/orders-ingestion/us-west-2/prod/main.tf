terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "sports-cards-terraform-state-bucket-us-west-2"
    key            = "orders-ingestion/us-west-2/prod/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "sports-cards-terraform-locks-us-west-2"
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
      Service     = "orders-ingestion"
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
  task_cpu         = "1024"
  task_memory      = "2048"
  desired_count    = 5
  assign_public_ip = false

  # Allow Lambda functions and workers to access API
  allowed_security_group_ids = [
    module.card_processor_lambda.security_group_id,
    module.user_service_lambda.security_group_id,
    module.data_sync_worker.security_group_id,
    module.image_processor_worker.security_group_id,
  ]
  log_retention_days = 30

  environment_variables = [
    {
      name  = "ENV"
      value = var.environment
    },
    {
      name  = "LOG_LEVEL"
      value = "warn"
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
  timeout             = 60
  memory_size         = 1024
  log_retention_days  = 30

  environment_variables = {
    ENV       = var.environment
    LOG_LEVEL = "warn"
  }

  enable_function_url = true
  function_url_auth_type = "AWS_IAM"

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
  timeout             = 30
  memory_size         = 1024
  log_retention_days  = 30

  environment_variables = {
    ENV       = var.environment
    LOG_LEVEL = "warn"
  }

  tags = local.common_tags
}

# ECS Worker Services
module "data_sync_worker" {
  source = "../../../../modules/ecs-worker"

  project_name        = var.project_name
  environment         = var.environment
  worker_name         = "data-sync"
  aws_region          = var.aws_region
  vpc_id              = var.vpc_id
  subnet_ids          = var.subnet_ids
  container_image     = var.data_sync_container_image
  task_cpu            = "1024"
  task_memory         = "2048"
  desired_count       = 3
  assign_public_ip    = false
  create_sqs_queue    = true
  log_retention_days  = 30

  environment_variables = [
    {
      name  = "ENV"
      value = var.environment
    },
    {
      name  = "SYNC_INTERVAL"
      value = "900"
    }
  ]

  sqs_message_retention_seconds = 1209600  # 14 days
  sqs_visibility_timeout_seconds = 300

  tags = local.common_tags
}

module "image_processor_worker" {
  source = "../../../../modules/ecs-worker"

  project_name        = var.project_name
  environment         = var.environment
  worker_name         = "image-processor"
  aws_region          = var.aws_region
  vpc_id              = var.vpc_id
  subnet_ids          = var.subnet_ids
  container_image     = var.image_processor_container_image
  task_cpu            = "2048"
  task_memory         = "4096"
  desired_count       = 5
  assign_public_ip    = false
  create_sqs_queue    = true
  log_retention_days  = 30

  environment_variables = [
    {
      name  = "ENV"
      value = var.environment
    },
    {
      name  = "MAX_IMAGE_SIZE"
      value = "20971520"
    }
  ]

  sqs_message_retention_seconds = 1209600  # 14 days
  sqs_visibility_timeout_seconds = 600
  sqs_max_receive_count = 5

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
  multi_az                  = true
  skip_final_snapshot       = false
  deletion_protection       = true
  backup_retention_period   = 30
  log_retention_days        = 30
  # Allow access from API, Lambda functions, and workers
  allowed_security_groups   = [
    module.api_service.api_security_group_id,
    module.card_processor_lambda.security_group_id,
    module.user_service_lambda.security_group_id,
    module.data_sync_worker.security_group_id,
    module.image_processor_worker.security_group_id,
  ]


  create_read_replicas      = true
  read_replica_count        = 2
  read_replica_instance_class = var.db_instance_class

  tags = local.common_tags
}

# SQS Queue
module "notifications_queue" {
  source = "../../../../modules/sqs-queue"

  project_name                = var.project_name
  environment                 = var.environment
  queue_name                  = "notifications"
  visibility_timeout_seconds  = 120
  message_retention_seconds   = 1209600  # 14 days
  create_alarms               = true
  queue_depth_alarm_threshold = 1000
  message_age_alarm_threshold = 600

  tags = local.common_tags
}

# CloudWatch Rules
module "daily_cleanup_rule" {
  source = "../../../../modules/cloudwatch-rule"

  project_name        = var.project_name
  environment         = var.environment
  rule_name           = "daily-cleanup"
  rule_description    = "Trigger daily cleanup tasks"
  schedule_expression = "cron(0 4 * * ? *)"
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
