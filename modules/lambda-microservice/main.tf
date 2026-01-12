terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

resource "aws_lambda_function" "main" {
  function_name = "${var.project_name}-${var.environment}-${var.service_name}"
  role          = aws_iam_role.lambda_role.arn
  handler       = var.handler
  runtime       = var.runtime
  timeout       = var.timeout
  memory_size   = var.memory_size

  filename         = var.lambda_package_path
  source_code_hash = fileexists(var.lambda_package_path) ? filebase64sha256(var.lambda_package_path) : null

  environment {
    variables = var.environment_variables
  }

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-${var.service_name}"
      Environment = var.environment
      Service     = var.service_name
    },
    var.tags
  )
}

resource "aws_lambda_function_url" "microservice" {
  count              = var.enable_function_url ? 1 : 0
  function_name      = aws_lambda_function.microservice.function_name
  authorization_type = var.function_url_auth_type

  cors {
    allow_origins     = var.cors_allow_origins
    allow_methods     = var.cors_allow_methods
    allow_headers     = var.cors_allow_headers
    expose_headers    = var.cors_expose_headers
    max_age           = var.cors_max_age
    allow_credentials = var.cors_allow_credentials
  }
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.microservice.function_name}"
  retention_in_days = var.log_retention_days

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-${var.service_name}-logs"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_security_group" "lambda" {
  name        = "${var.project_name}-${var.environment}-${var.service_name}-lambda-sg"
  description = "Security group for Lambda microservice"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-${var.service_name}-lambda-sg"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-${var.environment}-${var.service_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-${var.service_name}-lambda-role"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy" "lambda_custom" {
  count = var.custom_policy_json != "" ? 1 : 0
  name  = "${var.project_name}-${var.environment}-${var.service_name}-custom-policy"
  role  = aws_iam_role.lambda_role.id

  policy = var.custom_policy_json
}

resource "aws_lambda_permission" "api_gateway" {
  count         = var.enable_api_gateway_invoke ? 1 : 0
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.microservice.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = var.api_gateway_execution_arn
}
