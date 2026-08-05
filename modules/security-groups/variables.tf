# ===================================================================
# SECURITY GROUPS MODULE - VARIABLES
# ===================================================================

# ===================================================================
# REQUIRED VARIABLES
# ===================================================================
variable "vpc_id" {
  description   = "ID of the VPC where security groups will be created"
  type          = string
}

variable "environment" {
  description   = "Environment name (dev, staging, prod)"
  type          = string

  validation {
    condition       = contains(["dev", "staging", "prod"], var.environment)
    error_message   = "Environment must be one of: dev, staging, prod."
  }
}

variable "vpc_cidr" {
  description   = "CIDR block of the VPC"
  type          = string
}


# =============================================================================
# OPTIONAL VARIABLES WITH DEFAULTS
# =============================================================================
variable "project_name" {
  description = "Project name used for naming resources"
  type = string
  default = "smartcity"
}

variable "private_subnet_ids" {
  description = "IDs of private subnets (for bastion deployment)"
  type = list(string)
  default = []
}

variable "common_tags" {
  description = "Common tags applied to all resources"
  type = map(string)
  default = {}
}


# ===============================================================================
# BASTION CONFIGURATION
# ===============================================================================
variable "bastion_allowed_cidrs" {
  description = "CIDR blocks allowed to SSH into bastion hosts"
  type = list(string)
  default = []  # Must be explicitly set
}

variable "enable_bastion_ssh" {
  description = "Enable SSH access from bastion to other resources"
  type = bool
  default = false
}


# ================================================================================
# LOAD BALANCER CONFIGURATION
# ================================================================================
variable "load_balancer_health_check_port" {
  description = "Port used for load balancer health checks"
  type = number
  default = 80
}


# ================================================================================
# APPLICATION CONFIGURATION
# ================================================================================
variable "application_port" {
  description = "Port your application listens on"
  type = number
  default = 8080
}

variable "application_additional_ports" {
  description = "Additional ports to open from load balancer to application"
  type = list(number)
  default = []
}


# =========================================================================================
# DATABASE CONFIGURATION
# =========================================================================================
variable "database_port" {
  description = "Port your database listens on (e.g. 5432 for PostgreSQL, 3306 for MySQL)"
  type = number
  default = 5432
}

variable "enable_database_admin_access" {
  description = "Allow database access from bastion hosts for admin purposes"
  type = bool
  default = false
}


# ==========================================================================================
# CACHE/REDIS CONFIGURATION
# ==========================================================================================
variable "enable_cache" {
  description = "Enable cache/Redis security group"
  type = bool
  default = false
}

variable "cache_port" {
  description = "Port your cache/Redis listens on"
  type = number
  default = 6379
}


# ===========================================================================================
# MONITORING CONFIGURATION
# ===========================================================================================
variable "enable_monitoring" {
  description = "Enable monitoring security group (Prometheus, Grafana, etc.)"
  type = bool
  default = false
}

variable "grafana_port" {
  description = "Port Grafana listens on"
  type = number
  default = 3000
}

variable "prometheus_port" {
  description = "Port Prometheus listens on"
  type = number
  default = 9090
}