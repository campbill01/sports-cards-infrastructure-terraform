terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# IAM Users
resource "aws_iam_user" "users" {
  for_each = var.iam_users
  name     = "${var.project_name}-${var.environment}-${each.key}"
  path     = var.iam_path

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-${each.key}"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_iam_user_policy_attachment" "user_policies" {
  for_each = {
    for pair in flatten([
      for user, config in var.iam_users : [
        for policy in config.policies : {
          user   = user
          policy = policy
        }
      ]
    ]) : "${pair.user}-${pair.policy}" => pair
  }

  user       = aws_iam_user.users[each.value.user].name
  policy_arn = each.value.policy
}

# IAM Groups
resource "aws_iam_group" "groups" {
  for_each = var.iam_groups
  name     = "${var.project_name}-${var.environment}-${each.key}"
  path     = var.iam_path
}

resource "aws_iam_group_policy_attachment" "group_policies" {
  for_each = {
    for pair in flatten([
      for group, config in var.iam_groups : [
        for policy in config.policies : {
          group  = group
          policy = policy
        }
      ]
    ]) : "${pair.group}-${pair.policy}" => pair
  }

  group      = aws_iam_group.groups[each.value.group].name
  policy_arn = each.value.policy
}

resource "aws_iam_group_membership" "group_members" {
  for_each = var.iam_groups

  name  = "${var.project_name}-${var.environment}-${each.key}-membership"
  group = aws_iam_group.groups[each.key].name
  users = [for user in each.value.members : aws_iam_user.users[user].name]
}

# IAM Roles
resource "aws_iam_role" "roles" {
  for_each           = var.iam_roles
  name               = "${var.project_name}-${var.environment}-${each.key}"
  path               = var.iam_path
  assume_role_policy = each.value.assume_role_policy

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-${each.key}"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "role_policies" {
  for_each = {
    for pair in flatten([
      for role, config in var.iam_roles : [
        for policy in config.policies : {
          role   = role
          policy = policy
        }
      ]
    ]) : "${pair.role}-${pair.policy}" => pair
  }

  role       = aws_iam_role.roles[each.value.role].name
  policy_arn = each.value.policy
}

# Custom IAM Policies
resource "aws_iam_policy" "custom_policies" {
  for_each    = var.custom_policies
  name        = "${var.project_name}-${var.environment}-${each.key}"
  path        = var.iam_path
  description = each.value.description
  policy      = each.value.policy_json

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-${each.key}"
      Environment = var.environment
    },
    var.tags
  )
}

# Service-Linked Roles (optional)
resource "aws_iam_service_linked_role" "service_roles" {
  for_each         = var.service_linked_roles
  aws_service_name = each.value
  description      = "Service-linked role for ${each.value}"
}

# Access Keys (use with caution)
resource "aws_iam_access_key" "keys" {
  for_each = var.create_access_keys
  user     = aws_iam_user.users[each.key].name
}

# SSM Parameter Store for Access Keys (encrypted)
resource "aws_ssm_parameter" "access_key_id" {
  for_each = var.create_access_keys
  name     = "/${var.project_name}/${var.environment}/iam/${each.key}/access_key_id"
  type     = "SecureString"
  value    = aws_iam_access_key.keys[each.key].id

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-${each.key}-access-key-id"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_ssm_parameter" "secret_access_key" {
  for_each = var.create_access_keys
  name     = "/${var.project_name}/${var.environment}/iam/${each.key}/secret_access_key"
  type     = "SecureString"
  value    = aws_iam_access_key.keys[each.key].secret

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-${each.key}-secret-key"
      Environment = var.environment
    },
    var.tags
  )
}

# OIDC Provider for GitHub Actions / CI/CD
resource "aws_iam_openid_connect_provider" "oidc_provider" {
  for_each = var.oidc_providers

  url             = each.value.url
  client_id_list  = each.value.client_id_list
  thumbprint_list = each.value.thumbprint_list

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-${each.key}-oidc"
      Environment = var.environment
    },
    var.tags
  )
}
