# ===========================================================================
# Application Deployment Module - Variables
# ===========================================================================

# ===========================================================================
# REQUIRED VARIABLES
# ===========================================================================

variable "environment" {
    description = "Environment name (dev, staging, prod)"
    type        = string

    validation {
        condition       = contains(["dev", "staging", "prod"], var.environment)
        error_message   = "Environment must be one of: dev, staging, prod"
    }
}

variable "region" {
    description = "AWS region"
    type        = string
}

variable "eks_cluster_name" {
    description = "Name of the EKS cluster"
    type        = string
}

variable "eks_cluster_endpoint" {
    description = "Endpoint of the EKS cluster"
    type        = string
}

variable "eks_cluster_ca" {
    description = "Certificate authority data of the EKS cluster"
    type        = string
}


# ===========================================================================
# APPLICATION CONFIGURATION
# ===========================================================================

variable "api_image" {
    description = "Image for the API Gateway"
    type        = string
    default     = "smartcity/api-gateway:latest"
}

variable "worker_image" {
    description = "Image for the Sensor Worker"
    type        = string
    default     = "smartcity/sensor-worker:latest"
}

variable "api_port" {
    description = "Port for the API Gateway"
    type        = number
    default     = 8080
}

variable "metrics_port" {
    description = "Port for metrics collection"
    type        = number
    default     = 9090
}

variable "domain_name" {
    description = "Domain name for the application"
    type        = string
    default     = "smartcity.example.com"
}


# ===========================================================================
# DATABASE CONFIGURATION
# ===========================================================================

variable "rds_endpoint" {
    description = "RDS endpoint"
    type        = string
}

variable "rds_port" {
    description = "RDS port"
    type        = string
    default     = "5432"
}

variable "rds_db_name" {
    description = "RDS database name"
    type        = string
}

variable "rds_username" {
    description = "RDS username"
    type        = string
}

variable "rds_password" {
    description = "RDS password"
    type        = true
}


# ===========================================================================
# SQS CONFIGURATION
# ===========================================================================

variable "sqs_queue_url" {
    description = "SQS queue URL"
    type        = string
}


# ===========================================================================
# S3 CONFIGURATION
# ===========================================================================

variable "s3_bucket_name" {
    description = "S3 bucket name"
    type        = string
}


# ===========================================================================
# API KEY (for external integrations)
# ===========================================================================

variable "api_key" {
    description = "API key for external integration"
    type        = string
    sensitive   = true
    default     = ""
}


# ===========================================================================
# LOGGING
# ===========================================================================

variable "log_level" {
    description = "Log level (DEBUG, INFO, WARN, ERROR)"
    type        = string
    default     = "INFO"
}


# ===========================================================================
# SCALING CONFIGURATION
# ===========================================================================

variable "api_replicas" {
    description = "Number of replicas for API Gateway"
    type        = number
    default     = 2
}

variable "api_max_replicas" {
    description = "Maximum replicas for API Gateway"
    type        = number
    default     = 10
}

variable "worker_replicas" {
    description = "Number of replicas for Sensor Worker"
    type        = number
    default     = 2
}

variable "worker_max_replicas" {
    description = "Maximum replicas for Sensor Worker"
    type        = number
    default     = 20
}


# ===========================================================================
# RESOURCE LIMITS
# ===========================================================================

variable "api_cpu_request" {
    description = "CPU request for API Gateway"
    type        = string
    default     = "100m"
}

variable "api_cpu_limit" {
    description = "CPU limit for API Gateway"
    type        = string
    default     = "500m"
}

variable "api_memory_request" {
    description = "Memory request for API Gateway"
    type        = string
    default     = "256Mi"
}

variable "api_memory_limit" {
    description = "Memory limit for API Gateway"
    type        = string
    default     = "512Mi"
}

variable "worker_cpu_request" {
    description = "CPU request for Sensor Worker"
    type        = string
    default     = 100m
}

variable "worker_cpu_limit" {
    description = "CPU limit for Sensor Worker"
    type        = string
    default     = "100m"
}

variable "worker_memory_request" {
    description = "Memory request for Sensor Worker"
    type        = string
    default     = "256Mi"
}

variable "worker_memory_limit" {
    description = "Memory limit for Sensor Worker"
    type        = string
    default     = "1024Mi"
}


# ===========================================================================
# WORKER CONFIGURATION
# ===========================================================================

variable "worker_type" {
    description = "Type of worker (sensor, data, etc.)"
    type        = string
    default     = "sensor"
}


# ===========================================================================
# INGRESS CONFIGURATION
# ===========================================================================

variable "deploy_ingress_controller" {
    description = "Deploy NGINX Ingress Controller"
    type        = bool
    default     = true
}

variable "nginx_ingress_version" {
    description = "NGINX Ingress Controller Helm chart version"
    type        = string
    default     = "4.9.0"
}

variable "ingress_replicas" {
    description = "Number of replicas for Ingress Controller"
    type        = number
    default     = 2
}


# ===========================================================================
# TLS CONFIGURATION
# ===========================================================================

variable "enable_tls" {
    description = "Enable TLS for ingress"
    type        = bool
    default     = false
}

variable "tls_certificate" {
    description = "TLS certificate (base64 encoded)"
    type        = string
    sensitive   = true
    default     = ""
}

variable "tls_private_key" {
    description = "TLS private key (base64 encoded)"
    type        = string
    sensitive   = true
    default     = ""
}


# ===========================================================================
# MONITORING
# ===========================================================================

variable "enable_service_monitors" {
    description = "Enable ServiceMonitors for Prometheus"
    type        = bool
    default     = true
}

variable "deploy_monitoring" {
    description = "Deploy monitorng namespaces"
    type        = bool
    default     = true
}


# ===========================================================================
# COMMON TAGS
# ===========================================================================

variable "common_tags" {
    description = "Common tags applied to resources"
    type        = map(string)
    default     = {}
}