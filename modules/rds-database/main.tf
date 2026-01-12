terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
      configuration_aliases = [aws.replica]
    }
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-db-subnet-group"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_db_parameter_group" "main" {
  name   = "${var.project_name}-${var.environment}-db-params"
  family = var.parameter_group_family

  dynamic "parameter" {
    for_each = var.db_parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-db-params"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_db_instance" "main" {
  identifier     = "${var.project_name}-${var.environment}-db"
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted

  db_name  = var.database_name
  username = var.master_username
  password = var.master_password
  port     = var.database_port

  vpc_security_group_ids = [aws_security_group.db.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  parameter_group_name   = aws_db_parameter_group.main.name

  publicly_accessible = var.publicly_accessible
  multi_az            = var.multi_az

  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.project_name}-${var.environment}-db-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  deletion_protection = var.deletion_protection

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-db"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_security_group" "db" {
  name        = "${var.project_name}-${var.environment}-db-sg"
  description = "Security group for RDS database"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.database_port
    to_port         = var.database_port
    protocol        = "tcp"
    security_groups = var.allowed_security_groups
    cidr_blocks     = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-db-sg"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_cloudwatch_log_group" "db_logs" {
  for_each          = toset(var.enabled_cloudwatch_logs_exports)
  name              = "/aws/rds/instance/${aws_db_instance.main.identifier}/${each.value}"
  retention_in_days = var.log_retention_days

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-db-${each.value}-logs"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_db_instance" "read_replica" {
  count              = var.create_read_replicas ? var.read_replica_count : 0
  identifier         = "${var.project_name}-${var.environment}-db-replica-${count.index + 1}"
  replicate_source_db = aws_db_instance.main.identifier
  instance_class     = var.read_replica_instance_class != "" ? var.read_replica_instance_class : var.instance_class
  
  # Read replicas inherit most settings from source
  publicly_accessible = var.publicly_accessible
  skip_final_snapshot = var.skip_final_snapshot
  
  # Storage autoscaling
  max_allocated_storage = var.max_allocated_storage
  
  # Can be in different AZ for HA
  availability_zone = var.read_replica_availability_zones != null && length(var.read_replica_availability_zones) > count.index ? var.read_replica_availability_zones[count.index] : null
  
  vpc_security_group_ids = [aws_security_group.db.id]
  
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  
  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-db-replica-${count.index + 1}"
      Environment = var.environment
      ReplicaOf   = aws_db_instance.main.identifier
    },
    var.tags
  )
}

# Cross-Region Read Replica
# Note: This resource must be created with a separate provider for the target region
# The cross-region replica requires the source DB to have automated backups enabled
resource "aws_db_instance" "cross_region_replica" {
  count              = var.create_cross_region_replica ? 1 : 0
  provider           = aws.replica
  identifier         = "${var.project_name}-${var.environment}-db-cross-region-replica"
  replicate_source_db = aws_db_instance.main.arn
  instance_class     = var.read_replica_instance_class != "" ? var.read_replica_instance_class : var.instance_class
  
  # Storage settings
  storage_encrypted     = true
  kms_key_id            = var.cross_region_replica_kms_key_id != "" ? var.cross_region_replica_kms_key_id : null
  max_allocated_storage = var.max_allocated_storage
  
  # Cross-region replicas don't support Multi-AZ at creation
  publicly_accessible = var.publicly_accessible
  skip_final_snapshot = var.skip_final_snapshot
  
  # Note: VPC security groups and subnet groups must exist in target region
  # These should be passed via variables or created separately
  
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  
  tags = merge(
    {
      Name         = "${var.project_name}-${var.environment}-db-cross-region-replica"
      Environment  = var.environment
      ReplicaOf    = aws_db_instance.main.identifier
      ReplicaType  = "cross-region"
      SourceRegion = aws_db_instance.main.availability_zone
    },
    var.tags
  )
}
