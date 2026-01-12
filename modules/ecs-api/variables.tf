variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "container_image" {
  description = "Docker image for the API container"
  type        = string
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 8080
}

variable "task_cpu" {
  description = "CPU units for the task"
  type        = string
  default     = "256"
}

variable "task_memory" {
  description = "Memory for the task in MB"
  type        = string
  default     = "512"
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 2
}

variable "assign_public_ip" {
  description = "Assign public IP to tasks"
  type        = bool
  default     = true
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/health"
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "environment_variables" {
  description = "Environment variables for the container"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

variable "allowed_security_group_ids" {
  description = "List of security group IDs allowed to access the API"
  type        = list(string)
  default     = []
}

# EC2 and Auto Scaling variables
variable "ecs_ami_id" {
  description = "AMI ID for ECS-optimized EC2 instances"
  type        = string
  default     = ""  # Will use latest ECS-optimized AMI if not specified
}

variable "instance_type" {
  description = "EC2 instance type for ECS cluster"
  type        = string
  default     = "t3.medium"
}

variable "asg_min_size" {
  description = "Minimum size of Auto Scaling Group"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Maximum size of Auto Scaling Group"
  type        = number
  default     = 10
}

variable "asg_desired_capacity" {
  description = "Desired capacity of Auto Scaling Group"
  type        = number
  default     = 2
}

variable "asg_managed_termination_protection" {
  description = "Enable managed termination protection for capacity provider"
  type        = string
  default     = "DISABLED"
}

variable "asg_target_capacity" {
  description = "Target capacity percentage for ECS capacity provider managed scaling"
  type        = number
  default     = 100
}

variable "asg_min_scaling_step_size" {
  description = "Minimum scaling step size for capacity provider"
  type        = number
  default     = 1
}

variable "asg_max_scaling_step_size" {
  description = "Maximum scaling step size for capacity provider"
  type        = number
  default     = 10
}

variable "enable_autoscaling_policies" {
  description = "Enable CloudWatch-based auto scaling policies"
  type        = bool
  default     = true
}

variable "scale_up_adjustment" {
  description = "Number of instances to add when scaling up"
  type        = number
  default     = 1
}

variable "scale_up_cooldown" {
  description = "Cooldown period in seconds after scaling up"
  type        = number
  default     = 300
}

variable "scale_down_adjustment" {
  description = "Number of instances to remove when scaling down (use negative number)"
  type        = number
  default     = -1
}

variable "scale_down_cooldown" {
  description = "Cooldown period in seconds after scaling down"
  type        = number
  default     = 300
}

variable "cpu_high_threshold" {
  description = "CPU utilization threshold for scaling up"
  type        = number
  default     = 75
}

variable "cpu_high_evaluation_periods" {
  description = "Number of evaluation periods for high CPU alarm"
  type        = number
  default     = 2
}

variable "cpu_high_period" {
  description = "Period in seconds for high CPU metric evaluation"
  type        = number
  default     = 300
}

variable "cpu_low_threshold" {
  description = "CPU utilization threshold for scaling down"
  type        = number
  default     = 25
}

variable "cpu_low_evaluation_periods" {
  description = "Number of evaluation periods for low CPU alarm"
  type        = number
  default     = 2
}

variable "cpu_low_period" {
  description = "Period in seconds for low CPU metric evaluation"
  type        = number
  default     = 300
}
