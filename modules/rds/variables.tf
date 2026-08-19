# ======================================================================================
# RDS Module - Variables
# ======================================================================================

# ======================================================================================
# REQUIRED VARIABLES
# ======================================================================================

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "database_subnet_ids" {
  description = "List of subnet IDs for the database subnet group"
  type        = set(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for the database"
  type        = list(string)
}

variable "username" {
  description = "Database master username"
  type        = string
  sensitive   = true
}

variable "password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

# ======================================================================================
# OPTIONAL VARIABLES WITH DEFAULTS
# ======================================================================================

variable "project_name" {
  description = "Project name used for naming resources"
  type        = string
}

variable "common_tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}

# ======================================================================================
# DATABASE CONFIGURATION
# ======================================================================================

variable "database_name" {
  description = "Name of the database to create"
  type        = string
}

variable "port" {
  description = "Database port"
  type        = number
}

variable "postgres_version" {
  description = "PostgreSQL engine version"
  type        = string
}

variable "postgres_version_major" {
  description = "PostgreSQL major version (for parameter group family)"
  type        = string
}

# ======================================================================================
# INSTANCE CONFIGURATION
# ======================================================================================

variable "instance_class" {
  description = "RDS instance class (e.g., db.t3.medium, db.r5.large)"
  type        = string
}

variable "allocated_storage" {
  description = "Storage size in GB"
  type        = number
}

variable "max_allocated_storage" {
  description = "Maximum storage size in GB (for autoscaling)"
  type        = number
}

variable "storage_type" {
  description = "Storage type (gp2, gp3, io1)"
  type        = string
}

variable "storage_encrypted" {
  description = "Enable storage encryption"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "ARN of KMS key for encryption (creates new if empty)"
  type        = string
  default     = ""
}

# ======================================================================================
# HIGH AVAILABILITY
# ======================================================================================

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = false
}

# variable "availability_zone" {
#   description = "Availability zone for the database (required for Single-AZ)"
#   type        = string
#   default     = ""
# }

# ======================================================================================
# BACKUP CONFIGURATION
# ======================================================================================

variable "backup_retention_period" {
  description = "Number of days to retain backups (0 = disabled)"
  type        = number
}

variable "backup_window" {
  description = "GMT window for backups (e.g., 03:00-05:00)"
  type        = string
}

variable "maintenance_window" {
  description = "GMT window for maintenance (e.g., Mon:5:00-Mon:7:00)"
  type        = string
}

# ======================================================================================
# DELETION PROTECTION
# ======================================================================================

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

# ======================================================================================
# PARAMETER GROUPS
# ======================================================================================

variable "max_connections" {
  description = "Maximum database connections"
  type        = string
}

variable "shared_buffers" {
  description = "Shared buffers size"
  type        = string
}

variable "effective_cache_size" {
  description = "Effective cache size"
  type        = string
}

variable "work_mem" {
  description = "Work memory size"
  type        = string
}

variable "maintenance_work_mem" {
  description = "Maintenance work memory size"
  type        = string
  default     = "64MB"
}

variable "wal_buffers" {
  description = "WAL buffers size"
  type        = string
}

variable "random_page_cost" {
  description = "Random page cost"
  type        = string
}

variable "log_statement" {
  description = "Log statement level (none, ddl, mod, all)"
  type        = string
}

variable "log_min_duration_statement" {
  description = "Log queries slower than this (milliseconds)"
  type        = string
}

variable "extra_parameters" {
  description = "Extra parameters for the parameter group"
  type        = list(object({
    name          = string
    value         = string
    apply_method  = optional(string)
  }))
  default = []
}

# ======================================================================================
# OPTION GROUP
# ======================================================================================

variable "enable_option_group" {
  description = "Enable custom option group"
  type        = bool
  default     = false
}


# ======================================================================================
# MONITORING
# ======================================================================================

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
}

variable "performance_insights_retention_period" {
  description = "Performance Insights retention period in days (7, 31, 731)"
  type        = number
}

variable "performance_insights_kms_key_id" {
  description = "KMS key ID for Performance Insights"
  type        = string
  default     = ""
}

variable "monitoring_interval" {
  description = "Monitoring interval in seconds (0 = disabled)"
  type        = number
}

variable "monitoring_role_arn" {
  description = "ARN of IAM role for monitoring (creates new if empty)"
  type        = string
  default     = ""
}

# ======================================================================================
# LOGGING
# ======================================================================================

variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch"
  type        = list(string)
}

# ======================================================================================
# IAM AUTHENTICATION
# ======================================================================================

variable "iam_database_authentication_enabled" {
  description = "Enable IAM database authentication"
  type        = bool
  default     = false
}

# ======================================================================================
# NETWORK CONFIGURATATION
# ======================================================================================

variable "publicly_accessible" {
  description = "Make database publicly accessible (not recommended)"
  type        = bool
}

# ======================================================================================
# VERSION UPGRADES
# ======================================================================================

variable "allow_major_version_upgrade" {
  description = "Allow major version upgrades"
  type        = bool
  default     = false
}

variable "auto_minor_version_upgrade" {
  description = "Auto minor version upgrades"
  type        = bool
  default     = true
}

# ======================================================================================
# READ REPLICA
# ======================================================================================

variable "enable_read_replica" {
  description = "Enable read replica"
  type        = bool
  default     = false
}

variable "replica_instance_class" {
  description = "Instance class for read replica (empty = same as primary)"
  type        = string
  default     = ""
}

variable "replica_availability_zone" {
  description = "Availability zone for read replica"
  type        = string
  default     = ""
}

# ======================================================================================
# RDS PROXY
# ======================================================================================

variable "enable_rds_proxy" {
  description = "Enable RDS Proxy"
  type        = bool
  default     = false
}

variable "proxy_idle_client_timeout" {
  description = "Idle client timeout in secondes"
  type        = number
  default     = 1800
}

variable "proxy_max_connections_percent" {
  description = "Max connections percentage"
  type        = number
  default     = 100
}

variable "proxy_max_idle_connections_percent" {
  description = "Max idle connections percentage"
  type        = number
  default     = 50
}

variable "proxy_debug_logging" {
  description = "Enable debug logging for RDS Proxy"
  type        = bool
  default     = false
}

# ======================================================================================
# TIMEOUTS
# ======================================================================================

variable "timeout_create" {
  description = "Create timeout in minutes"
  type        = string
  default     = "60m"
}

variable "timeout_update" {
  description = "Update timeout in minutes"
  type        = string
  default     = "60m"
}

variable "timeout_delete" {
  description = "Delete timeout in minutes"
  type        = string
  default     = "60m"
}