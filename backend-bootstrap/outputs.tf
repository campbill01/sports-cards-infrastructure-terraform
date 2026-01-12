output "us_east_1_state_bucket" {
  description = "S3 bucket name for us-east-1 state"
  value       = aws_s3_bucket.terraform_state.id
}

output "us_east_1_lock_table" {
  description = "DynamoDB table name for us-east-1 state locks"
  value       = aws_dynamodb_table.terraform_locks.id
}

output "us_west_2_state_bucket" {
  description = "S3 bucket name for us-west-2 state"
  value       = aws_s3_bucket.terraform_state_us_west_2.id
}

output "us_west_2_lock_table" {
  description = "DynamoDB table name for us-west-2 state locks"
  value       = aws_dynamodb_table.terraform_locks_us_west_2.id
}
