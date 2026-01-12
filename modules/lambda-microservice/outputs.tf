output "function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.microservice.function_name
}

output "function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.microservice.arn
}

output "invoke_arn" {
  description = "Lambda invoke ARN"
  value       = aws_lambda_function.microservice.invoke_arn
}

output "function_url" {
  description = "Lambda function URL (if enabled)"
  value       = var.enable_function_url ? aws_lambda_function_url.microservice[0].function_url : null
}

output "role_arn" {
  description = "Lambda execution role ARN"
  value       = aws_iam_role.lambda_role.arn
}

output "security_group_id" {
  description = "Lambda security group ID"
  value       = aws_security_group.lambda.id
}
