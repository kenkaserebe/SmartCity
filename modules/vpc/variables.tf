# SmartCity/modules/vpc/variables.tf

# ============================================================================================================
# VPC Module - Variables
# ============================================================================================================
# All variables required for the VPC module with validation and descriptions
# ============================================================================================================

# ============================================================================================================
# REQUIRED VARIABLES (No defaults)
# ============================================================================================================

variable "environment" {
  description   = "Environment name (dev, staging, prod) - used for naming and tagging"
  type          = string
  validation {
    condition       = contains(["dev", "staging", "prod"], var.environment)
    error_message   = "Environment must be one of: dev, staging, prod."
  }
}


variable "vpc_cidr" {
  description   = "CIDR block for the VPC"
  type          = string
  validation {
    condition       = can(cidrhost(var.vpc_cidr, 0))
    error_message   = "vpc_cidr must be a valid CIDR block."
  }
}


variable "public_subnet_cidrs" {
  description   = "List of CIDR blocks for public subnets (must match availability_zones count)"
  type          = list(string)
  validation {
    condition       = length(var.public_subnet_cidrs) >= 2
    error_message   = "At least 2 public subnets are required for high availability."
  }
  validation {
    condition       = alltrue([for cidr in var.public_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message   = "All public_subnet_cidrs must be valid CIDR blocks."
  }
}


variable "private_subnet_cidrs" {
  description   = "List of CIDR blocks for private subnets (must match availability_zones count)"
  type          = list(string)
  validation {
    condition       = length(var.private_subnet_cidrs) >= 2
    error_message   = "At least 2 private subnets are required for high availability."
  }
  validation {
    condition       = alltrue([for cidr in var.private_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message   = "All private_subnet_cidrs must be valid CIDR blocks."
  }
}


variable "database_subnet_cidrs" {
  description   = "List of CIDR blocks for database subnets (must match availability_zones count)"
  type          = list(string)
  validation {
    condition       = length(var.database_subnet_cidrs) >= 2
    error_message   = "At least 2 database subnets are required for RDS/Aurora high availability."
  }
  validation {
    condition       = alltrue([for cidr in var.database_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message   = "All database_subnet_cidrs must be valid CIDR blocks."
  }
}


variable "availability_zones" {
  description   = "List of availability zones to use (must match subnet counts)"
  type          = list(string)
  validation {
    condition       = length(var.availability_zones) >= 2
    error_message   = "At least 2 availability zones are required for high availability."
  }
  validation {
    condition       = length(var.availability_zones) == length(var.public_subnet_cidrs)
    error_message   = "Number of availability zones must equal number of public subnets."
  }
  validation {
    condition       = length(var.availability_zones) == length(var.private_subnet_cidrs)
    error_message   = "Number of availability zones must equal number of private subnets."
  }
  validation {
    condition       = length(var.availability_zones) == length(var.database_subnet_cidrs)
    error_message   = "Number of availability zones must equal number of database subnets."
  }
}


# ===========================================================================================================
# OPTIONAL VARIABLES (WITH DEFAULTS)
# ===========================================================================================================
variable "project_name" {
  description   = "Project name used for naming resources"
  type          = string
  default       = "smartcity"
}

variable "region" {
  description   = "AWS region where resources will be created"
  type          = string
  default       = "eu-west-2"
}

variable "common_tags" {
  description   = "Common tags applied to all resources (merged with resource-specific tags)"
  type          = string
  default       = {}
}

variable "enable_nat_gateway" {
  description   = "Enable NAT gateways for private subnet internet access"
  type          = bool
  default       = true
}

variable "enable_flow_logs" {
  description   = "Enable VPC flow logs for network traffic monitoring and compliance"
  type          = bool
  default       = false
}

variable "flow_logs_retention_days" {
  description   = "Number of days to retain VPC flow logs in S3"
  type          = number
  default       = 30
  validation {
    condition = var.flow_logs_retention_days >= 1 && var.flow_logs_retention_days <= 3650
    error_message = "flow_logs_retention_days must be between 1 and 3650 days."
  }
}

variable "enable_deletion_protection" {
  description   = "Enable deletion protection on the VPC (AWS VPC deletion protection is not natively supported, this flag is for future use or to tag resources)"
  type          = bool
  default       = false
}


# ===========================================================================================================
# ADVANCED CONFIGURATION (Usually keep defaults)
# ===========================================================================================================
variable "instance_tenancy" {
  description   = "Tenancy option for instances lauched in the VPC (default or dedicated)"
  type          = string
  default       = "default"
  validation {
    condition       = contains(["default", "dedicated"], var.instance_tenancy)
    error_message   = "instance_tenancy must be either 'default' or 'dedicated'."
  }
}

variable "enable_dns_support" {
  description   = "Enable DNS support in the VPC (required for EKS AND RDS)"
  type          = bool
  default       = true
}

variable "enable_dns_hostname" {
  description   = "Enable DNS hostnames in the VPC (required for EKS and RDS)"
  type          = bool
  default       = true
}