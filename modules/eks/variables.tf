# ===========================================================================================
# EKS Module - Variables
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

variable "private_subnet_ids" {
  description   = "List of private subnet IDs for the EKS cluster and nodes"
  type          = set(string)
}

variable "cluster_role_arn" {
  description   = "ARN of the IAM role for the EKS cluster"
  type          = string
}

variable "node_role_arn" {
  description   = "ARN of the IAM role for the EKS node group"
  type          = string
}

variable "cluster_security_group_ids" {
  description   = "List of security group IDs for the EKS cluster"
  type          = list(string)
}


# ===========================================================================================
# OPTIONAL VARIABLES WITH DEFAULTS
# ===========================================================================================

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


# ===========================================================================================
# KUBERNETES VERSION
# ===========================================================================================

variable "kubernetes_version" {
  description   = "Kubernetes version for the cluster"
  type          = string
}


# ===========================================================================================
# CLUSTER ENDPOINT CONFIGURATION
# ===========================================================================================

variable "endpoint_private_access" {
  description   = "Enable private API server endpoint (VPC access only)"
  type          = bool
  default       = true
}

variable "endpoint_public_access" {
  description   = "Enable public API server endpoint (internet access)"
  type          = bool
  default       = false
}

variable "endpoint_public_access_cidrs" {
  description   = "CIDR blocks allowed to access the public API endpoint"
  type          = list(string)
  default       = [ "0.0.0.0/0" ]
}


# ===========================================================================================
# CLUSTER LOGGING
# ===========================================================================================

variable "cluster_log_types" {
  description   = "List of log types to enable for the cluster"
  type          = list(string)
  default       = [ "api", "audit", "authenticator", "controllerManager", "scheduler" ]
}

# ===========================================================================================
# ENCRYPTION
# ===========================================================================================

variable "kms_key_arn" {
  description   = "ARN of the KMS key for secrets encryption (creates new if empty)"
  type          = string
  default       = ""
}

# ===========================================================================================
# NODE GROUP CONFIGURATION
# ===========================================================================================

variable "node_instance_types" {
  description   = "List of EC2 instance types for the node group"
  type          = list(string)
  default       = [ "t3.medium" ]
}

variable "node_capacity_type" {
  description   = "Capacity type for nodes (ON_DEMAND or SPOT)"
  type          = string
  default       = "ON_DEMAND"

  validation {
    condition       = contains(["ON_DEMAND", "SPOT"], var.node_capacity_type)
    error_message   = "Capacity type must be ON_DEMAND or SPOT."
  }
}

variable "node_desired_size" {
  description   = "Desired number of nodes in the node group"
  type          = number
  default       = 2
}

variable "node_min_size" {
  description   = "Minimum number of nodes in the node group"
  type          = number
  default       = 1
}

variable "node_max_size" {
  description   = "Maximum number of nodes in the node group"
  type          = number
  default       = 5
}

variable "node_max_unavailable" {
  description   = "Maximum number of nodes unavailable during updates"
  type          = number
  default       = 1
}

variable "node_ssh_key_name" {
  description   = "EC2 key pair name for SSH access to nodes (empty = no SSH)"
  type          = string
  default       = ""
}

variable "node_ssh_security_group_ids" {
  description   = "Security group IDs for SSH access to nodes"
  type          = list(string)
  default       = []
}

# ===========================================================================================
# LAUNCH TEMPLATE CONFIGURATION
# ===========================================================================================

variable "launch_template_name" {
  description   = "Name of an existing launch template (empty = create from default)"
  type          = string
  default       = ""
}

variable "launch_template_version" {
  description   = "Version of the launch template (defaults to latest)"
  type          = string
  default       = "$Latest"
}


# ===========================================================================================
# SPECIALIZED NODE GROUP
# ===========================================================================================

variable "enable_specialized_node_group" {
  description   = "Enable a specialized node group for specific workloads"
  type          = bool
  default       = false
}

variable "specialized_instance_types" {
  description   = "Instance types for specialized node group"
  type          = list(string)
  default       = [ "t3.large" ]
}

variable "specialized_capacity_type" {
  description   = "Capacity type for specialized nodes"
  type          = string
  default       = "ON_DEMAND"
}

variable "specialized_desired_size" {
  description   = "Desired size of specialized node group"
  type          = number
  default       = 1
}

variable "specialized_min_size" {
  description   = "Minimum size of specialized node group"
  type          = number
  default       = 0
}

variable "specialized_max_size" {
  description   = "Maximum size of specialized node group"
  type          = number
  default       = 3
}

variable "specialized_max_unavailable" {
  description   = "Max unavailable nodes during specialized node group updates"
  type          = number
  default       = 1
}

# ===========================================================================================
# OIDC PROVIDER
# ===========================================================================================

variable "create_oidc_provider" {
  description   = "Create OIDC provider for IRSA"
  type          = bool
  default       = true
}


# ===========================================================================================
# ADD-ON VERSION
# ===========================================================================================

variable "vpc_cni_version" {
  description   = "Version of VPC-CNI add-on"
  type          = string
}

variable "coredns_version" {
  description   = "Version of CoreDNS add-on"
  type          = string
}

variable "kube_proxy_version" {
  description   = "Version of kube-proxy add-on"
  type          = string
}

variable "enable_lb_controller" {
  description   = "Enable AWS Load Balancer Controller add-on"
  type          = bool
  default       = false
}

variable "lb_controller_version" {
  description   = "Version of AWS Load Balancer Controller add-on"
  type          = string
  default       = "latest"
}
