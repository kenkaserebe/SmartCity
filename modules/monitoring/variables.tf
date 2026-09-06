# =============================================================================
# Monitoring Module - Variables
# =============================================================================

# =============================================================================
# REQUIRED VARIABLES
# =============================================================================

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type = string

  validation {
    condition = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "region" {
  description = "AWS region where resources will be created"
  type = string
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type = string
}


# =============================================================================
# OPTIONAL VARIABLES WITH DEFAULTS
# =============================================================================

variable "project_name" {
  description = "Project name used for naming resources"
  type = string
  default = "smartcity"
}

variable "common_tags" {
  description = "Common tags applied to all resources"
  type = map(string)
  default = {}
}


# =============================================================================
# CLOUDWATCH CONFIGURATION
# =============================================================================

variable "cloudwatch_log_retention" {
  description = "CloudWatch log retention in days"
  type = number
  default = 30
}

variable "enable_cloudwatch_alarms" {
  description = "Enable CloudWatch metric alarms"
  type = bool
  default = true
}


# =============================================================================
# RDS CONFIGURATION
# =============================================================================

variable "rds_instance_id" {
  description = "ID of the RDS instance for monitoring"
  type = string
  default = ""
}

variable "rds_cpu_threshold" {
  description = "RDS CPU utilization threshold for alarm"
  type = number
  default = 80
}


# =============================================================================
# SQS CONFIGURATION
# =============================================================================

variable "sqs_queue_name" {
  description = "Name of the SQS queue for monitoring"
  type = string
  default = ""
}

variable "sqs_queue_url" {
  description = "URL of the SQS queue for monitoring"
  type = string
  default = ""
}

variable "sqs_depth_threshold" {
  description = "SQS queue depth threshold for alarm"
  type = number
  default = 100
}


# =============================================================================
# EKS CONFIGURATION
# =============================================================================

variable "eks_min_nodes" {
  description = "Minimum number of EKS nodes for alarms"
  type = number
  default = 1
}


# =============================================================================
# OIDC CONFIGURATION
# =============================================================================

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA"
  type = string
  # default = ""
}

variable "oidc_issuer_url" {
  description = "URL of the OIDC issuer"
  type = string
  default = ""
}


# =============================================================================
# PROMETHEUS CONFIGURATION
# =============================================================================

variable "enable_prometheus" {
  description = "Enable Prometheus monitoring"
  type = bool
  default = true
}

variable "prometheus_s3_bucket" {
  description = "S3 bucket name for Prometheus storage (empty = create new)"
  type = string
  default = ""
}


# =============================================================================
# GRAFANA CONFIGURATION
# =============================================================================

variable "enable_grafana" {
  description = "Enable Grafana dashboards"
  type = bool
  default = true
}

# =============================================================================
# ALERT CONFIGURATION
# =============================================================================

variable "enable_sns_alerts" {
  description = "Enable SNS for alerts"
  type = bool
  default = true
}

variable "alert_email" {
  description = "Email address for alerts"
  type = string
  default = ""
}

variable "alert_slack_webhook" {
  description = "Slack webhook URL for alerts"
  type = string
  default = ""
}

variable "alarm_actions" {
  description = "List of SNS topic ARNs for alarm actions"
  type = list(string)
  default = []
}
