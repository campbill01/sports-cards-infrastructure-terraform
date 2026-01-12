output "cluster_id" {
  description = "ECS cluster ID"
  value       = aws_ecs_cluster.api.id
}

output "cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.api.name
}

output "service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.api.name
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.api.dns_name
}

output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.api.arn
}

output "task_role_arn" {
  description = "ECS task role ARN"
  value       = aws_iam_role.ecs_task_role.arn
}

output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = aws_security_group.alb.id
}

output "api_security_group_id" {
  description = "API ECS tasks security group ID"
  value       = aws_security_group.api.id
}
