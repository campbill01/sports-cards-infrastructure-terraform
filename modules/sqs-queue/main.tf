terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

resource "aws_sqs_queue" "main" {
  name                       = "${var.project_name}-${var.environment}-${var.queue_name}"
  delay_seconds              = var.delay_seconds
  max_message_size           = var.max_message_size
  message_retention_seconds  = var.message_retention_seconds
  receive_wait_time_seconds  = var.receive_wait_time_seconds
  visibility_timeout_seconds = var.visibility_timeout_seconds
  fifo_queue                 = var.fifo_queue
  content_based_deduplication = var.fifo_queue ? var.content_based_deduplication : null

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-${var.queue_name}"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_sqs_queue" "dlq" {
  count = var.create_dlq ? 1 : 0
  name  = "${var.project_name}-${var.environment}-${var.queue_name}-dlq"

  message_retention_seconds = var.dlq_message_retention_seconds
  fifo_queue                = var.fifo_queue

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-${var.queue_name}-dlq"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_sqs_queue_redrive_policy" "main" {
  count     = var.create_dlq ? 1 : 0
  queue_url = aws_sqs_queue.main.id

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[0].arn
    maxReceiveCount     = var.max_receive_count
  })
}

resource "aws_sqs_queue_policy" "main" {
  count     = var.queue_policy_json != "" ? 1 : 0
  queue_url = aws_sqs_queue.main.id

  policy = var.queue_policy_json
}

resource "aws_cloudwatch_metric_alarm" "queue_depth" {
  count               = var.create_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-${var.queue_name}-depth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = var.alarm_period
  statistic           = "Average"
  threshold           = var.queue_depth_alarm_threshold
  alarm_description   = "This metric monitors SQS queue depth"
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.main.name
  }

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-${var.queue_name}-depth-alarm"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_cloudwatch_metric_alarm" "queue_age" {
  count               = var.create_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-${var.queue_name}-age"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = "AWS/SQS"
  period              = var.alarm_period
  statistic           = "Maximum"
  threshold           = var.message_age_alarm_threshold
  alarm_description   = "This metric monitors SQS message age"
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.main.name
  }

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-${var.queue_name}-age-alarm"
      Environment = var.environment
    },
    var.tags
  )
}
