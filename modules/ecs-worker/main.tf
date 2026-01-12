terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

resource "aws_ecs_cluster" "worker" {
  name = "${var.project_name}-${var.environment}-${var.worker_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-${var.worker_name}-cluster"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_ecs_cluster_capacity_providers" "worker" {
  cluster_name = aws_ecs_cluster.worker.name

  capacity_providers = [aws_ecs_capacity_provider.worker.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.worker.name
    weight            = 1
    base              = 0
  }
}

resource "aws_ecs_task_definition" "worker" {
  family                   = "${var.project_name}-${var.environment}-${var.worker_name}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = var.worker_name
    image     = var.container_image
    essential = true
    environment = var.environment_variables
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.worker.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = var.worker_name
      }
    }
  }])
}

resource "aws_ecs_service" "worker" {
  name            = "${var.project_name}-${var.environment}-${var.worker_name}-service"
  cluster         = aws_ecs_cluster.worker.id
  task_definition = aws_ecs_task_definition.worker.arn
  desired_count   = var.desired_count

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.worker.name
    weight            = 1
    base              = 0
  }

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.worker.id]
    assign_public_ip = var.assign_public_ip
  }

  enable_execute_command = var.enable_execute_command

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-${var.worker_name}-service"
      Environment = var.environment
    },
    var.tags
  )

  depends_on = [aws_ecs_cluster_capacity_providers.worker]
}

resource "aws_security_group" "worker" {
  name        = "${var.project_name}-${var.environment}-${var.worker_name}-sg"
  description = "Security group for worker ECS tasks"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-${var.worker_name}-sg"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_cloudwatch_log_group" "worker" {
  name              = "/ecs/${var.project_name}-${var.environment}-${var.worker_name}"
  retention_in_days = var.log_retention_days

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-${var.worker_name}-logs"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.project_name}-${var.environment}-${var.worker_name}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-${var.environment}-${var.worker_name}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "worker_custom" {
  count = var.custom_policy_json != "" ? 1 : 0
  name  = "${var.project_name}-${var.environment}-${var.worker_name}-custom-policy"
  role  = aws_iam_role.ecs_task_role.id

  policy = var.custom_policy_json
}

# SQS Queue for worker processing (optional)
resource "aws_sqs_queue" "worker_queue" {
  count                     = var.create_sqs_queue ? 1 : 0
  name                      = "${var.project_name}-${var.environment}-${var.worker_name}-queue"
  delay_seconds             = var.sqs_delay_seconds
  max_message_size          = var.sqs_max_message_size
  message_retention_seconds = var.sqs_message_retention_seconds
  receive_wait_time_seconds = var.sqs_receive_wait_time_seconds
  visibility_timeout_seconds = var.sqs_visibility_timeout_seconds

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-${var.worker_name}-queue"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_sqs_queue" "worker_dlq" {
  count = var.create_sqs_queue ? 1 : 0
  name  = "${var.project_name}-${var.environment}-${var.worker_name}-dlq"

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-${var.worker_name}-dlq"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_sqs_queue_redrive_policy" "worker_queue" {
  count     = var.create_sqs_queue ? 1 : 0
  queue_url = aws_sqs_queue.worker_queue[0].id

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.worker_dlq[0].arn
    maxReceiveCount     = var.sqs_max_receive_count
  })
}

# EC2 Launch Template for ECS cluster
resource "aws_launch_template" "ecs" {
  name_prefix   = "${var.project_name}-${var.environment}-${var.worker_name}-"
  image_id      = var.ecs_ami_id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs.name
  }

  vpc_security_group_ids = [aws_security_group.ecs_instance.id]

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    cluster_name = aws_ecs_cluster.worker.name
  }))

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      {
        Name        = "${var.project_name}-${var.environment}-${var.worker_name}-ecs-instance"
        Environment = var.environment
      },
      var.tags
    )
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group for ECS EC2 instances
resource "aws_autoscaling_group" "ecs" {
  name                = "${var.project_name}-${var.environment}-${var.worker_name}-asg"
  vpc_zone_identifier = var.subnet_ids
  min_size            = var.asg_min_size
  max_size            = var.asg_max_size
  desired_capacity    = var.asg_desired_capacity
  health_check_type   = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-${var.worker_name}-ecs-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ECS Capacity Provider
resource "aws_ecs_capacity_provider" "worker" {
  name = "${var.project_name}-${var.environment}-${var.worker_name}-cp"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs.arn
    managed_termination_protection = var.asg_managed_termination_protection

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = var.asg_target_capacity
      minimum_scaling_step_size = var.asg_min_scaling_step_size
      maximum_scaling_step_size = var.asg_max_scaling_step_size
    }
  }

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-${var.worker_name}-cp"
      Environment = var.environment
    },
    var.tags
  )
}

# IAM Role for ECS EC2 instances
resource "aws_iam_role" "ecs_instance" {
  name = "${var.project_name}-${var.environment}-${var.worker_name}-ecs-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_instance" {
  role       = aws_iam_role.ecs_instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs" {
  name = "${var.project_name}-${var.environment}-${var.worker_name}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance.name
}

# Security Group for ECS EC2 instances
resource "aws_security_group" "ecs_instance" {
  name        = "${var.project_name}-${var.environment}-${var.worker_name}-ecs-instance-sg"
  description = "Security group for ECS EC2 instances"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-${var.worker_name}-ecs-instance-sg"
      Environment = var.environment
    },
    var.tags
  )
}

# Auto Scaling Policies
resource "aws_autoscaling_policy" "scale_up" {
  count                  = var.enable_autoscaling_policies ? 1 : 0
  name                   = "${var.project_name}-${var.environment}-${var.worker_name}-scale-up"
  autoscaling_group_name = aws_autoscaling_group.ecs.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = var.scale_up_adjustment
  cooldown               = var.scale_up_cooldown
}

resource "aws_autoscaling_policy" "scale_down" {
  count                  = var.enable_autoscaling_policies ? 1 : 0
  name                   = "${var.project_name}-${var.environment}-${var.worker_name}-scale-down"
  autoscaling_group_name = aws_autoscaling_group.ecs.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = var.scale_down_adjustment
  cooldown               = var.scale_down_cooldown
}

# CloudWatch Alarms for Auto Scaling
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  count               = var.enable_autoscaling_policies ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-${var.worker_name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.cpu_high_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = var.cpu_high_period
  statistic           = "Average"
  threshold           = var.cpu_high_threshold

  dimensions = {
    ClusterName = aws_ecs_cluster.worker.name
    ServiceName = aws_ecs_service.worker.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_up[0].arn]

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-${var.worker_name}-cpu-high"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  count               = var.enable_autoscaling_policies ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-${var.worker_name}-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.cpu_low_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = var.cpu_low_period
  statistic           = "Average"
  threshold           = var.cpu_low_threshold

  dimensions = {
    ClusterName = aws_ecs_cluster.worker.name
    ServiceName = aws_ecs_service.worker.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_down[0].arn]

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-${var.worker_name}-cpu-low"
      Environment = var.environment
    },
    var.tags
  )
}
