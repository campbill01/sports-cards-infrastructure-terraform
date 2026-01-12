terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

resource "aws_cloudwatch_event_rule" "main" {
  name                = "${var.project_name}-${var.environment}-${var.rule_name}"
  description         = var.rule_description
  schedule_expression = var.schedule_expression
  event_pattern       = var.event_pattern
  is_enabled          = var.is_enabled

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-${var.rule_name}"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_cloudwatch_event_target" "lambda" {
  count     = var.target_lambda_arn != "" ? 1 : 0
  rule      = aws_cloudwatch_event_rule.main.name
  target_id = "${var.rule_name}-lambda-target"
  arn       = var.target_lambda_arn
  input     = var.target_input
}

resource "aws_lambda_permission" "eventbridge" {
  count         = var.target_lambda_arn != "" ? 1 : 0
  statement_id  = "AllowExecutionFromEventBridge-${var.rule_name}"
  action        = "lambda:InvokeFunction"
  function_name = var.target_lambda_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.main.arn
}

resource "aws_cloudwatch_event_target" "ecs" {
  count     = var.target_ecs_cluster_arn != "" ? 1 : 0
  rule      = aws_cloudwatch_event_rule.main.name
  target_id = "${var.rule_name}-ecs-target"
  arn       = var.target_ecs_cluster_arn
  role_arn  = var.target_ecs_cluster_arn != "" ? aws_iam_role.eventbridge_ecs[0].arn : null

  ecs_target {
    task_definition_arn = var.target_ecs_task_definition_arn
    task_count          = var.target_ecs_task_count
    launch_type         = var.target_ecs_launch_type

    network_configuration {
      subnets          = var.target_ecs_subnets
      security_groups  = var.target_ecs_security_groups
      assign_public_ip = var.target_ecs_assign_public_ip
    }
  }
}

resource "aws_iam_role" "eventbridge_ecs" {
  count = var.target_ecs_cluster_arn != "" ? 1 : 0
  name  = "${var.project_name}-${var.environment}-${var.rule_name}-eventbridge-ecs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "events.amazonaws.com"
      }
    }]
  })

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-${var.rule_name}-eventbridge-ecs-role"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_iam_role_policy" "eventbridge_ecs" {
  count = var.target_ecs_cluster_arn != "" ? 1 : 0
  name  = "${var.project_name}-${var.environment}-${var.rule_name}-eventbridge-ecs-policy"
  role  = aws_iam_role.eventbridge_ecs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ecs:RunTask"
      ]
      Resource = [
        var.target_ecs_task_definition_arn
      ]
    },
    {
      Effect = "Allow"
      Action = [
        "iam:PassRole"
      ]
      Resource = ["*"]
    }]
  })
}

resource "aws_cloudwatch_event_target" "sqs" {
  count     = var.target_sqs_queue_arn != "" ? 1 : 0
  rule      = aws_cloudwatch_event_rule.main.name
  target_id = "${var.rule_name}-sqs-target"
  arn       = var.target_sqs_queue_arn
}

resource "aws_cloudwatch_event_target" "sns" {
  count     = var.target_sns_topic_arn != "" ? 1 : 0
  rule      = aws_cloudwatch_event_rule.main.name
  target_id = "${var.rule_name}-sns-target"
  arn       = var.target_sns_topic_arn
}
