output "api_alb_dns" {
  description = "API ALB DNS name"
  value       = module.api_service.alb_dns_name
}

output "card_processor_function_url" {
  description = "Card processor Lambda function URL"
  value       = module.card_processor_lambda.function_url
  sensitive   = true
}

output "user_service_function_name" {
  description = "User service Lambda function name"
  value       = module.user_service_lambda.function_name
}

output "data_sync_queue_url" {
  description = "Data sync worker queue URL"
  value       = module.data_sync_worker.queue_url
  sensitive   = true
}

output "image_processor_queue_url" {
  description = "Image processor worker queue URL"
  value       = module.image_processor_worker.queue_url
  sensitive   = true
}

output "database_endpoint" {
  description = "RDS database endpoint"
  value       = module.database.db_endpoint
  sensitive   = true
}

output "notifications_queue_url" {
  description = "Notifications queue URL"
  value       = module.notifications_queue.queue_url
  sensitive   = true
}

output "daily_cleanup_rule_arn" {
  description = "Daily cleanup CloudWatch rule ARN"
  value       = module.daily_cleanup_rule.rule_arn
}

output "database_read_replica_endpoints" {
  description = "RDS read replica endpoints"
  value       = module.database.read_replica_endpoints
  sensitive   = true
}


output "iam_role_arns" {
  description = "IAM role ARNs"
  value       = module.iam.role_arns
}

output "iam_user_arns" {
  description = "IAM user ARNs"
  value       = module.iam.user_arns
}

output "iam_custom_policy_arns" {
  description = "Custom IAM policy ARNs"
  value       = module.iam.custom_policy_arns
}

output "api_security_group_id" {
  description = "API security group ID"
  value       = module.api_service.api_security_group_id
}

output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = module.api_service.alb_security_group_id
}

output "database_security_group_id" {
  description = "Database security group ID"
  value       = module.database.security_group_id
}
