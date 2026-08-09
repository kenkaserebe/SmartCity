# ===========================================================================================
# IAM Module - Variables
# ===========================================================================================

# ===========================================================================================
# REQUIRED VARIABLES
# ===========================================================================================

variable "environment" {
  description   = "Environment name (dev, staging, prod)"
  type          = string

  validation {
    condition       = contains(["dev", "staging", "prod"], var.environment)
    error_message   = "Environment must be one of: dev, staging, prod."
  }
}

variable "region" {
  description   = "AWS region where resources will be created"
  type          = string
}

# ============================================================================================
# OPTIONAL VARIABLES WITH DEFAULTS
# ============================================================================================

variable "project_name" {
  description   = "Project name used for naming resources"
  type          = string
  default       = "smartcity"
}

variable "common_tags" {
  description   = "Common tags applied to all resources"
  type          = map(string)
  default       = {}
}

# =============================================================================================
# EKS CONFIGURATION
# =============================================================================================

variable "create_oidc_provider" {
  description   = "Create OIDC provider for IRSA (requires EKS cluster to exist)"
  type          = bool
  default       = false
}

variable "namespace" {
  description   = "Kubernetes namespace for IRSA service accounts"
  type          = string
  default       = "default"
}

# ==============================================================================================
# SERVICE ACCESS FLAGS
# ==============================================================================================

variable "enable_s3_access" {
  description   = "Enable S3 access for application"
  type          = bool
  default       = false
}

variable "enable_sqs_access" {
  description   = "Enable SQS access for application"
  type          = bool
  default       = false
}

variable "enable_rds_access" {
  description   = "Enable RDS IAM authentication access for application"
  type          = bool
  default       = false
}

variable "enable_ssm_access" {
  description   = "Enable SSM access for nodes (for Session Manager)"
  type          = bool
  default       = false
}

# ==========================================================================================
# RESOURCES NAMES (Required if access is enabled)
# ==========================================================================================

variable "s3_bucket_name" {
  description   = "Nameof the S3 bucket for application access"
  type          = string
  default       = ""
}

variable "sqs_queue_name" {
  description   = "Name of the SQS queue for application access"
  type          = string
  default       = ""
}

variable "sqs_dlq_name" {
  description   = "Name of the SQS dead letter queue"
  type          = string
  default       = ""
}

variable "rds_resource_id" {
  description   = "RDS resource ID (e.g., db-XXXXXX) for IAM authentication"
  type          = string
  default       = ""
}

variable "rds_username" {
  description   = "RDS username for IAM authentication"
  type          = string
  default       = ""
}

# ==============================================================================================
# EKS NODE POLICY ARNS (Overridable)
# ==============================================================================================

variable "eks_node_policy_arns" {
  description   = "Additional IAM policy ARNs to attach to EKS node role"
  type          = list(string)
  default       = []
}