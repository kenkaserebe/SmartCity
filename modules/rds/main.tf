# ======================================================================================
# RDS Module - SmartCity IoT Platform
# ======================================================================================
# Creates a PostgreSQL database with:
# - Multi-AZ deployment
# - Automated backups with retention
# - Performance Insights
# - Enhanced monitoring
# - Proper security groups and subnet groups
# - Deletion protection (prod)
# ======================================================================================

terraform {
  backend "s3" {}
}

# ======================================================================================
# DATA SOURCES
# ======================================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ======================================================================================
# 1. DATABASE SUBNET GROUP
# ======================================================================================
# Required for RDS to know which subnets to use
# ======================================================================================

resource "aws_db_subnet_group" "main" {
  name = "${var.project_name}-${var.environment}-db-subnet-group"
  description = "Database subnet group for ${var.project_name}-${var.environment}"
  subnet_ids = var.database_subnet_ids

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-db-subnet-group"
    Environment = var.environment
    Component   = "database"
  })
}

# ======================================================================================
# 2. DATABASE PARAMETER GROUP
# ======================================================================================
# Custom parameter group for PostgreSQL optimisation
# ======================================================================================

resource "aws_db_parameter_group" "main" {
  name = "${var.project_name}-${var.environment}-postgres-${var.postgres_version}"
  family = "postgres${var.postgres_version_major}"
  description = "Custom parameter group for ${var.project_name}-${var.environment}"

  parameter {
    name = "max_connections"
    value = var.max_connections
  }

  parameter {
    name = "shared_buffers"
    value = var.shared_buffers
  }

  parameter {
    name = "effective_cache_size"
    value = var.effective_cache_size
  }

  parameter {
    name = "work_mem"
    value = var.work_mem
  }

  parameter {
    name = "maintenance_work_mem"
    value = var.maintenance_work_mem
  }

  parameter {
    name = "wal_buffers"
    value = var.wal_buffers
  }

  parameter {
    name = "random_page_cost"
    value = var.random_page_cost
  }

  parameter {
    name = "log_statement"
    value = var.log_statement
  }

  parameter {
    name = "log_min_duration_statement"
    value = var.log_min_duration_statement
  }
  
  dynamic "parameter" {
    for_each = var.extra_parameters
    content {
      name = parameter.value.name
      value = parameter.value.value
      apply_method = try(parameter.value.apply_method, "immediate")
    }
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-postgres-params"
    Environment = var.environment
    Component   = "database"
  })
}

# ======================================================================================
# 3. DATABASE OPTION GROUP
# ======================================================================================
# Optional: Use if you need specific extensions
# ======================================================================================

resource "aws_db_option_group" "main" {
  count = var.enable_option_group ? 1 : 0

  name = "${var.project_name}-${var.environment}-postgres-options"
  option_group_description = "Option group for ${var.project_name}-${var.environment}"
  engine_name = "postgres"
  major_engine_version = var.postgres_version_major

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-postgres-options"
    Environment = var.environment
    Component   = "database"
  })
}

# ======================================================================================
# 4. PRIMARY DATABASE INSTANCE
# ======================================================================================

resource "aws_db_instance" "main" {
  # Identifier
  identifier = "${var.project_name}-${var.environment}-postgres"

  # Engine
  engine = "postgres"
  engine_version = var.postgres_version
#   family = "postgres${var.postgres_version_major}"
  engine_version_actual = var.postgres_version

  # Instance Type
  instance_class = var.instance_class

  # Storage
  allocated_storage = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type = var.storage_type
  storage_encrypted = var.storage_encrypted
  kms_key_id = var.kms_key_arn != "" ? var.kms_key_arn : null

  # Database Settings
#   database_name = var.database_name
  username = var.username
  password = var.password
  port = var.port

  # Network
  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = var.security_group_ids
  availability_zone = var.availability_zone

  # High Availability
  multi_az = var.multi_az

  # Backup
  backup_retention_period = var.backup_retention_period
  backup_window = var.backup_window
  maintenance_window = var.maintenance_window

  # Deletion Protection
  deletion_protection = var.deletion_protection

  # Parameter Groups
  parameter_group_name = aws_db_parameter_group.main.name
  option_group_name = var.enable_option_group ? aws_db_option_group.main[0].name : null

  # Monitoring
  performance_insights_enabled = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_retention_period
  performance_insights_kms_key_id = var.performance_insights_kms_key_id

  # Enhanced Monitoring
  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_role_arn != "" ? var.monitoring_role_arn : aws_iam_role.rds_monitoring[0].arn

  # CloudWatch Logs Export
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  # IAM Database Authentication
  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  # Public Accessibility
  publicly_accessible = var.publicly_accessible

  # Allow major version upgrade
  allow_major_version_upgrade = var.allow_major_version_upgrade

  # Auto Minor Version Upgrade
  auto_minor_version_upgrade = var.auto_minor_version_upgrade

  # Copy tags to snapshots
  copy_tags_to_snapshot = true

  # Timeouts
  timeouts {
    create = var.timeout_create
    update = var.timeout_update
    delete = var.timeout_delete
  }

  lifecycle {
    ignore_changes = [ 
        password     # Ignore password changes to avoid unnecessary updates
     ]
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-postgres"
    Environment = var.environment
    Component   = "database"
    Engine      = "postgres"
  })

  depends_on = [ 
    aws_db_subnet_group.main,
    aws_db_parameter_group.main
   ]
}

# ======================================================================================
# 5. READ REPLICA
# ======================================================================================

resource "aws_db_instance" "replica" {
  count = var.enable_read_replica ? 1 : 0

  identifier = "${var.project_name}-${var.environment}-postgres-replica"

  # Replica from primary
  replicate_source_db = aws_db_instance.main.identifier

  # Instance Type (can be smaller than primary)
  instance_class = var.replica_instance_class != "" ? var.replica_instance_class : var.instance_class

  # Availability Zone
  availability_zone = var.replica_availability_zone

  # Backup (replicas don't need backups; they inherit from primary)
  backup_retention_period = 0

  # Deletion Protection
  deletion_protection = var.deletion_protection

  # Monitoring
  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_role_arn != "" ? var.monitoring_role_arn : aws_iam_role.rds_monitoring[0].arn

  # Performance Insights
  performance_insights_enabled = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_retention_period

  # Copy tags
  copy_tags_to_snapshot = true

  # Lifecycle
  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-postgres-replica"
    Environment = var.environment
    Component   = "database"
    Engine      = "postgres"
    Service     = "read-replica"
  })
}

# ======================================================================================
# 6. IAM ROLE FOR ENHANCED MONITORING
# ======================================================================================
resource "aws_iam_role" "rds_monitoring" {
  count = var.monitoring_role_arn == "" ? 1 : 0

  name = "${var.project_name}-${var.environment}-rds-monitoring-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
        Effect = "Allow"
        Principal = {
            Service = "monitoring.rds.amazonaws.com"
        }
        Action = "sts:AssumeRole"
    }]
  })

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-rds-monitoring-role"
    Environment = var.environment
    Component   = "database"
    Service     = "monitoring"
  })
}

resource "aws_iam_policy_attachment" "rds_monitoring" {
  count = var.monitoring_role_arn == "" ? 1 : 0

  name = "${var.project_name}-${var.environment}-rds-monitoring-attachment"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
  roles = [aws_iam_role.rds_monitoring[0].name]
}

# ======================================================================================
# 7. RDS PROXY
# ======================================================================================

resource "aws_db_proxy" "main" {
  count = var.enable_rds_proxy ? 1 : 0

  name = "${var.project_name}-${var.environment}-rds-proxy"
  engine_family = "POSTGRESQL"
  auth {
    auth_scheme = "SECRETS"
    secret_arn = aws_secretsmanager_secret.db_password[0].arn
    iam_auth = "DISABLED"
  }
  role_arn = aws_iam_role.rds_proxy[0].arn
  vpc_subnet_ids = var.database_subnet_ids
  vpc_security_group_ids = var.security_group_ids
  require_tls = true
  idle_client_timeout = var.proxy_idle_client_timeout
#   max_connections_percent = var.proxy_max_connection_percent
#   max_idle_connections_percent = var.proxy_max_idle_connections_percent

  # Debug logging
  debug_logging = var.proxy_debug_logging

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-rds-proxy"
    Environment = var.environment
    Component   = "database"
    Service     = "proxy"
  })
}

# IAM Role for RDS Proxy
resource "aws_iam_role" "rds_proxy" {
  count = var.enable_rds_proxy ? 1 : 0

  name = "${var.project_name}-${var.environment}-rds-proxy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
        Effect = "Allow"
        Principal = {
            Service = "rdsproxy.amazonaws.com"
        }
        Action = "sts:AssumeRole"
    }]
  })

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-rds-proxy-role"
    Environment = var.environment
    Component   = "database"
    Service     = "proxy"
  })  
}

resource "aws_iam_role_policy_attachment" "rds_proxy" {
  count = var.enable_rds_proxy ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSProxyRole"
  role = aws_iam_role.rds_proxy[0].name
}

# Secret for database password (for RDS Proxy)
resource "aws_secretsmanager_secret" "db_password" {
  count = var.enable_rds_proxy ? 1 : 0

  name = "${var.project_name}-${var.environment}-db-password"
  description = "Database password for ${var.project_name}-${var.environment}"

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-db-password"
    Environment = var.environment
    Component   = "database"
  })
}

resource "aws_secretsmanager_secret_version" "db_password" {
  count = var.enable_rds_proxy ? 1 : 0

  secret_id = aws_secretsmanager_secret.db_password[0].id
  secret_string = var.password
}

resource "aws_db_proxy_target" "main" {
  count = var.enable_rds_proxy ? 1 : 0

  db_instance_identifier = aws_db_instance.main.id
  db_proxy_name = aws_db_proxy.main[0].name
  target_group_name = "default"
}
