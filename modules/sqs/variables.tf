# =============================================================================
# SQS Module - Variables
# =============================================================================

# =============================================================================
# REQUIRED VARIABLES
# =============================================================================

variable "environment" {
  description   = "Environment name (dev, staging, prod)"
  type          = string

  validation {
    condition       = contains(["dev", "staging", "prod"], var.environment)
    error_message   = "Environment must be one of: dev, staging, prod."
  }
}


# =============================================================================
# OPTIONAL VARIABLES WITH DEFAULTS
# =============================================================================

variable "project_name" {
  description   = "Project name used for naming resources"
  type          = string
}

variable "common_tags" {
  description   = "Common tags applied to all resources"
  type          = map(string)
  default       = {}
}


# =============================================================================
# QUEUE CONFIGURATION
# =============================================================================

variable "fifo_queue" {
  description   = "Enable FIFO queue (ordered processing)"
  type          = bool
}

variable "content_based_deduplication" {
  description   = "Enable content-based deduplication (FIFO only)"
  type          = bool
  default       = false
}

variable "deduplication_scope" {
  description   = "Deduplication scope for FIFO (queue or messageGroup)"
  type          = string
  default       = "queue"

  validation {
    condition       = contains(["queue", "messageGroup"], var.deduplication_scope)
    error_message   = "Deduplication scope must be 'queue' or 'messageGroup'."
  }
}

variable "fifo_throughput_limit" {
  description   = "FIFO throughput limit (perQueue or perMessageGroupId)"
  type          = string
  default       = "perQueue"
}

variable "delay_seconds" {
  description   = "Delay in seconds before messages become visible (0-900)"
  type          = number
}

variable "max_message_size" {
  description   = "Maximum message size in bytes (1024-262144)"
  type          = number
}

variable "message_retention_seconds" {
  description   = "Message retention in seconds (60-1209600)"
  type          = number
}

variable "receive_wait_time_seconds" {
  description   = "Receive wait time for long polling (0-20)"
  type          = number
}

variable "visibility_timeout_seconds" {
  description   = "Visibility timeout in seconds (0-43200)"
  type          = number
}


# =============================================================================
# DEAD-LETTER QUEUE (DLQ)
# =============================================================================

variable "enable_dlq" {
  description   = "Enable dead-letter queue"
  type          = bool
}

variable "dlq_message_retention_seconds" {
  description   = "DLQ message retention in seconds (60-1209600)"
  type          = number
}

variable "max_receive_count" {
  description   = "Maximum receive count before moving to DLQ"
  type          = number
}


# =============================================================================
# ENCRYPTION
# =============================================================================

variable "kms_key_arn" {
  description   = "ARN of KMS key for encryption (empty = AWS managed KMS)"
  type          = string
  default       = ""
}

variable "kms_data_key_reuse_period_seconds" {
  description   = "KMS data key reuse period in seconds (60-86400)"
  type          = number
}


# =============================================================================
# SENSOR QUEUE 
# =============================================================================

variable "enable_sensor_queue" {
  description   = "Enable separate sensor data queue"
  type          = bool
}

variable "sensor_fifo_queue" {
  description   = "Enable FIFO for sensor queue"
  type          = bool
  default       = false
}

variable "sensor_delay_seconds" {
  description   = "Sensor queue delay in seconds"
  type          = number
  default       = 0
}

variable "sensor_max_message_size" {
  description   = "Sensor queue max message size"
  type          = number
  default       = 262144
}

variable "sensor_message_retention_seconds" {
  description   = "Sensor queue message retention"
  type          = number
  default       = 345600
}

variable "sensor_visibility_timeout_seconds" {
  description   = "Sensor queue visibility timeout"
  type          = number
  default       = 60
}

variable "sensor_max_receive_count" {
  description   = "Sensor queue max receive count before DLQ"
  type          = number
  default       = 5
}


# =============================================================================
# QUEUE POLICIES
# =============================================================================

variable "enable_queue_policy" {
  description   = "Enable queue policies"
  type          = bool
}

variable "allowed_principals" {
  description   = "List of AWS principals allowed to access the queue"
  type          = list(string)
}

variable "sensor_allowed_principals" {
  description   = "List of AWS principals allowed to access the sensor queue"
  type          = list(string)
  default       = []
}


# =============================================================================
# S3 NOTIFICATIONS
# =============================================================================

variable "enable_s3_notifications" {
  description   = "Enable s3 bucket notifications to SQS"
  type          = bool
}

variable "s3_bucket_id" {
  description   = "ID of the S3 bucket for notification"
  type          = string
  default       = ""
}

variable "s3_events" {
  description   = "S3 events to trigger notifications"
  type          = list(string)
  default       = [ "s3:ObjectCreated:*" ]
}

variable "s3_filter_prefix" {
  description   = "S3 object key prefix filter"
  type          = string
  default       = ""
}

variable "s3_filter_suffix" {
  description   = "S3 object key suffix filter"
  type          = string
  default       = ""
}


# =============================================================================
# IAM POLICY
# =============================================================================

variable "create_iam_policy" {
  description   = "Create an IAM policy for queue access"
  type          = bool
}


# =============================================================================
# CLOUDWATCH ALARMS
# =============================================================================

variable "enable_cloudwatch_alarms" {
  description   = "Enable CloudWatch alarms for queue monitoring"
  type          = bool
}

variable "queue_depth_threshold" {
  description   = "Threshold for queue depth alarm"
  type          = number
}

variable "dlq_depth_threshold" {
  description   = "Threshold for DLQ depth alarm"
  type          = number
}

variable "alarm_actions" {
  description   = "List of SNS topic ARNs for alarm actions"
  type          = list(string)
}
