output "rule_id" {
  description = "CloudWatch Event Rule ID"
  value       = aws_cloudwatch_event_rule.main.id
}

output "rule_arn" {
  description = "CloudWatch Event Rule ARN"
  value       = aws_cloudwatch_event_rule.main.arn
}

output "rule_name" {
  description = "CloudWatch Event Rule name"
  value       = aws_cloudwatch_event_rule.main.name
}
