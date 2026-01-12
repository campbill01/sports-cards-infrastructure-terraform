output "cluster_id" {
  description = "ECS cluster ID"
  value       = aws_ecs_cluster.worker.id
}

output "cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.worker.name
}

output "service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.worker.name
}

output "task_role_arn" {
  description = "ECS task role ARN"
  value       = aws_iam_role.ecs_task_role.arn
}

output "security_group_id" {
  description = "Worker security group ID"
  value       = aws_security_group.worker.id
}

output "queue_url" {
  description = "SQS queue URL (if created)"
  value       = var.create_sqs_queue ? aws_sqs_queue.worker_queue[0].url : null
}

output "queue_arn" {
  description = "SQS queue ARN (if created)"
  value       = var.create_sqs_queue ? aws_sqs_queue.worker_queue[0].arn : null
}

output "dlq_url" {
  description = "SQS DLQ URL (if created)"
  value       = var.create_sqs_queue ? aws_sqs_queue.worker_dlq[0].url : null
}

output "dlq_arn" {
  description = "SQS DLQ ARN (if created)"
  value       = var.create_sqs_queue ? aws_sqs_queue.worker_dlq[0].arn : null
}
