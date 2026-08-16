# ======================================================================================
# RDS Module - Outputs
# ======================================================================================

# ======================================================================================
# DATABASE INFORMATION
# ======================================================================================

output "db_instance_id" {
  description = "ID of the database instance"
  value = aws_db_instance.main.id
}

output "db_instance_arn" {
  description = "ARN of the database instance"
  value = aws_db_instance.main.arn
}

output "db_instance_name" {
  description = "Name of the database"
  value = aws_db_instance.main.db_name
}

output "db_endpoint" {
  description = "Endpoint of the database instance"
  value = aws_db_instance.main.endpoint
}

output "db_address" {
  description = "Address of the database instance"
  value = aws_db_instance.main.address
}

output "db_port" {
  description = "Port of the database instance"
  value = aws_db_instance.main.port
}

output "db_resource_id" {
  description = "Resource ID of the database instance"
  value = aws_db_instance.main.resource_id
}

output "db_status" {
  description = "Status of the database instance"
  value = aws_db_instance.main.status
}

# ======================================================================================
# DATABASE CREDENTIALS
# ======================================================================================

output "db_username" {
  description = "Database master username"
  value = var.username
  sensitive = true
}

# Password is intentionally NOT output for security reasons
# Use AWS Secrets Manager or SSM Parameter Store instead

# ======================================================================================
# SUBNET GROUP
# ======================================================================================

output "db_subnet_group_name" {
  description = "Name of the database subnet group"
  value = aws_db_subnet_group.main.name
}

# ======================================================================================
# PARAMETER GROUP
# ======================================================================================

output "db_parameter_group_name" {
  description = "Name of the database parameter group"
  value = aws_db_parameter_group.main.name
}

# ======================================================================================
# READ REPLICA
# ======================================================================================

output "replica_endpoint" {
  description = "Endpoint of the read replica"
  value = try(aws_db_instance.replica[0].endpoint, null)
}

output "replica_address" {
  description = "Address of the read replica"
  value = try(aws_db_instance.replica[0].address, null)
}

output "replica_id" {
  description = "ID of the read replica"
  value = try(aws_db_instance.replica[0].id, null)
}

# ======================================================================================
# RDS PROXY
# ======================================================================================

output "rds_proxy_endpoint" {
  description = "Endpoint of the RDS Proxy"
  value = try(aws_db_proxy.main[0].endpoint, null)
}

output "rds_proxy_arn" {
  description = "ARN of the RDS Proxy"
  value = try(aws_db_proxy.main[0].arn, null)
}

# ======================================================================================
# KMS KEY
# ======================================================================================

output "kms_key_arn" {
  description = "ARN of the KMS key used for encryption"
  value = var.kms_key_arn != "" ? var.kms_key_arn : null
}

# ======================================================================================
# SUMMARY
# ======================================================================================

output "rds_summary" {
  description = "Summary of RDS resources"
  value = {
    instance_id = aws_db_instance.main.id
    instance_class = var.instance_class
    engine_version = var.postgres_version
    storage_size_gb = var.allocated_storage
    multi_az = var.multi_az
    backup_retention = var.backup_retention_period
    deletion_protected = var.deletion_protection
    read_replica = var.enable_read_replica
    rds_proxy = var.enable_rds_proxy
    endpoint = aws_db_instance.main.endpoint
  }
}
