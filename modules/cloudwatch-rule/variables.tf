variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "rule_name" {
  description = "Name of the CloudWatch Event Rule"
  type        = string
}

variable "rule_description" {
  description = "Description of the rule"
  type        = string
  default     = ""
}

variable "schedule_expression" {
  description = "Schedule expression (e.g., rate(5 minutes) or cron(0 12 * * ? *))"
  type        = string
  default     = ""
}

variable "event_pattern" {
  description = "Event pattern as JSON string"
  type        = string
  default     = ""
}

variable "is_enabled" {
  description = "Enable the rule"
  type        = bool
  default     = true
}

variable "target_input" {
  description = "Input to pass to target"
  type        = string
  default     = ""
}

# Lambda target
variable "target_lambda_arn" {
  description = "ARN of Lambda function to invoke"
  type        = string
  default     = ""
}

# ECS target
variable "target_ecs_cluster_arn" {
  description = "ARN of ECS cluster"
  type        = string
  default     = ""
}

variable "target_ecs_task_definition_arn" {
  description = "ARN of ECS task definition"
  type        = string
  default     = ""
}

variable "target_ecs_task_count" {
  description = "Number of ECS tasks to run"
  type        = number
  default     = 1
}

variable "target_ecs_launch_type" {
  description = "ECS launch type (FARGATE or EC2)"
  type        = string
  default     = "FARGATE"
}

variable "target_ecs_subnets" {
  description = "List of subnet IDs for ECS tasks"
  type        = list(string)
  default     = []
}

variable "target_ecs_security_groups" {
  description = "List of security group IDs for ECS tasks"
  type        = list(string)
  default     = []
}

variable "target_ecs_assign_public_ip" {
  description = "Assign public IP to ECS tasks"
  type        = bool
  default     = false
}

# SQS target
variable "target_sqs_queue_arn" {
  description = "ARN of SQS queue"
  type        = string
  default     = ""
}

# SNS target
variable "target_sns_topic_arn" {
  description = "ARN of SNS topic"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
