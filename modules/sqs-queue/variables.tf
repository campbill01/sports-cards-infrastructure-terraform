variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "queue_name" {
  description = "Name of the SQS queue"
  type        = string
}

variable "delay_seconds" {
  description = "Delay seconds for message delivery"
  type        = number
  default     = 0
}

variable "max_message_size" {
  description = "Maximum message size in bytes"
  type        = number
  default     = 262144
}

variable "message_retention_seconds" {
  description = "Message retention period in seconds"
  type        = number
  default     = 345600
}

variable "receive_wait_time_seconds" {
  description = "Receive wait time in seconds (long polling)"
  type        = number
  default     = 0
}

variable "visibility_timeout_seconds" {
  description = "Visibility timeout in seconds"
  type        = number
  default     = 30
}

variable "fifo_queue" {
  description = "Create a FIFO queue"
  type        = bool
  default     = false
}

variable "content_based_deduplication" {
  description = "Enable content-based deduplication for FIFO queues"
  type        = bool
  default     = false
}

variable "create_dlq" {
  description = "Create a dead letter queue"
  type        = bool
  default     = true
}

variable "max_receive_count" {
  description = "Maximum receives before sending to DLQ"
  type        = number
  default     = 3
}

variable "dlq_message_retention_seconds" {
  description = "DLQ message retention in seconds"
  type        = number
  default     = 1209600
}

variable "queue_policy_json" {
  description = "Custom queue policy JSON"
  type        = string
  default     = ""
}

variable "create_alarms" {
  description = "Create CloudWatch alarms for the queue"
  type        = bool
  default     = false
}

variable "queue_depth_alarm_threshold" {
  description = "Alarm threshold for queue depth"
  type        = number
  default     = 1000
}

variable "message_age_alarm_threshold" {
  description = "Alarm threshold for message age in seconds"
  type        = number
  default     = 300
}

variable "alarm_evaluation_periods" {
  description = "Number of periods for alarm evaluation"
  type        = number
  default     = 2
}

variable "alarm_period" {
  description = "Period in seconds for alarm evaluation"
  type        = number
  default     = 300
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
