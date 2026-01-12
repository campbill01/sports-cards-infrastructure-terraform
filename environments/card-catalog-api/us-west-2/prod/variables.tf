variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "sports-cards"
}

variable "environment" {

variable "cost_code" {
  description = "Cost code for resource tagging"
  type        = string
  default     = "J9K0L1M2"
}
  description = "Environment name"

variable "cost_code" {
  description = "Cost code for resource tagging"
  type        = string
  default     = "J9K0L1M2"
}
  type        = string

variable "cost_code" {
  description = "Cost code for resource tagging"
  type        = string
  default     = "J9K0L1M2"
}
  default     = "prod"

variable "cost_code" {
  description = "Cost code for resource tagging"
  type        = string
  default     = "J9K0L1M2"
}
}

variable "cost_code" {
  description = "Cost code for resource tagging"
  type        = string
  default     = "J9K0L1M2"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs (private subnets for production)"
  type        = list(string)
}

# API Service Variables
variable "api_container_image" {
  description = "Docker image for API service"
  type        = string
}

variable "api_container_port" {
  description = "API container port"
  type        = number
  default     = 8080
}

# Lambda Variables
variable "card_processor_package_path" {
  description = "Path to card processor Lambda package"
  type        = string
  default     = "lambda-packages/card-processor.zip"
}

variable "user_service_package_path" {
  description = "Path to user service Lambda package"
  type        = string
  default     = "lambda-packages/user-service.zip"
}

# Worker Variables
variable "data_sync_container_image" {
  description = "Docker image for data sync worker"
  type        = string
}

variable "image_processor_container_image" {
  description = "Docker image for image processor worker"
  type        = string
}

# Database Variables
variable "db_name" {
  description = "Database name"
  type        = string
  default     = "sportscards"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "Database instance class"
  type        = string
  default     = "db.r5.large"
}

variable "db_allocated_storage" {
  description = "Database allocated storage in GB"
  type        = number
  default     = 100
}
