output "user_arns" {
  description = "Map of user names to ARNs"
  value       = { for k, v in aws_iam_user.users : k => v.arn }
}

output "user_names" {
  description = "Map of user keys to full user names"
  value       = { for k, v in aws_iam_user.users : k => v.name }
}

output "group_arns" {
  description = "Map of group names to ARNs"
  value       = { for k, v in aws_iam_group.groups : k => v.arn }
}

output "group_names" {
  description = "Map of group keys to full group names"
  value       = { for k, v in aws_iam_group.groups : k => v.name }
}

output "role_arns" {
  description = "Map of role names to ARNs"
  value       = { for k, v in aws_iam_role.roles : k => v.arn }
}

output "role_names" {
  description = "Map of role keys to full role names"
  value       = { for k, v in aws_iam_role.roles : k => v.name }
}

output "custom_policy_arns" {
  description = "Map of custom policy names to ARNs"
  value       = { for k, v in aws_iam_policy.custom_policies : k => v.arn }
}

output "access_key_ssm_paths" {
  description = "Map of SSM parameter paths for access keys"
  value = {
    for k in var.create_access_keys : k => {
      access_key_id     = aws_ssm_parameter.access_key_id[k].name
      secret_access_key = aws_ssm_parameter.secret_access_key[k].name
    }
  }
  sensitive = true
}

output "oidc_provider_arns" {
  description = "Map of OIDC provider ARNs"
  value       = { for k, v in aws_iam_openid_connect_provider.oidc_provider : k => v.arn }
}
