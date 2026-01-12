variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
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
  default     = "Z5A6B7C8"
}
  description = "Environment name"

variable "cost_code" {
  description = "Cost code for resource tagging"
  type        = string
  default     = "Z5A6B7C8"
}
  type        = string

variable "cost_code" {
  description = "Cost code for resource tagging"
  type        = string
  default     = "Z5A6B7C8"
}
  default     = "dev"

variable "cost_code" {
  description = "Cost code for resource tagging"
  type        = string
  default     = "Z5A6B7C8"
}
}

variable "cost_code" {
  description = "Cost code for resource tagging"
  type        = string
  default     = "Z5A6B7C8"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "assign_public_ip" {
  description = "Assign public IP to tasks"
  type        = bool
  default     = true
}

# API Service Variables
variable "api_container_image" {
  description = "Docker image for API service"
  type        = string
  default     = "nginx:latest"
}

variable "api_container_port" {
  description = "API container port"
  type        = number
  default     = 8080
}

variable "api_task_cpu" {
  description = "API task CPU"
  type        = string
  default     = "256"
}

variable "api_task_memory" {
  description = "API task memory"
  type        = string
  default     = "512"
}

variable "api_desired_count" {
  description = "API desired task count"
  type        = number
  default     = 1
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
  default     = "ubuntu:latest"
}

variable "data_sync_desired_count" {
  description = "Data sync worker desired count"
  type        = number
  default     = 1
}

variable "image_processor_container_image" {
  description = "Docker image for image processor worker"
  type        = string
  default     = "ubuntu:latest"
}

variable "worker_task_cpu" {
  description = "Worker task CPU"
  type        = string
  default     = "256"
}

variable "worker_task_memory" {
  description = "Worker task memory"
  type        = string
  default     = "512"
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
  default     = "changeme123"
}

variable "db_instance_class" {
  description = "Database instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Database allocated storage in GB"
  type        = number
  default     = 20
}
