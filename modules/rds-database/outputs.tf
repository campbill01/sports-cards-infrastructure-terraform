output "db_instance_id" {
  description = "Database instance ID"
  value       = aws_db_instance.main.id
}

output "db_instance_arn" {
  description = "Database instance ARN"
  value       = aws_db_instance.main.arn
}

output "db_endpoint" {
  description = "Database endpoint"
  value       = aws_db_instance.main.endpoint
}

output "db_address" {
  description = "Database address"
  value       = aws_db_instance.main.address
}

output "db_port" {
  description = "Database port"
  value       = aws_db_instance.main.port
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.main.db_name
}

output "security_group_id" {
  description = "Database security group ID"
  value       = aws_security_group.db.id
}

output "read_replica_endpoints" {
  description = "List of read replica endpoints"
  value       = aws_db_instance.read_replica[*].endpoint
}

output "read_replica_addresses" {
  description = "List of read replica addresses"
  value       = aws_db_instance.read_replica[*].address
}

output "read_replica_ids" {
  description = "List of read replica instance IDs"
  value       = aws_db_instance.read_replica[*].id
}

output "cross_region_replica_endpoint" {
  description = "Cross-region read replica endpoint"
  value       = var.create_cross_region_replica ? aws_db_instance.cross_region_replica[0].endpoint : null
}

output "cross_region_replica_address" {
  description = "Cross-region read replica address"
  value       = var.create_cross_region_replica ? aws_db_instance.cross_region_replica[0].address : null
}

output "cross_region_replica_id" {
  description = "Cross-region read replica instance ID"
  value       = var.create_cross_region_replica ? aws_db_instance.cross_region_replica[0].id : null
}
