# ===========================================================================================
# EKS Module - SmartCity IoT Platform
# ===========================================================================================
# Creates an EKS cluster with:
# - Control plane with proper logging and encryption
# - Managed node groups with autoscaling
# - OIDC provider for IRSA
# - Cluster add-ons (VPC-CNI, CoreDNS, kube-proxy)
# - AWS Load Balancer Controller integration
# ===========================================================================================

terraform {
  backend "s3" {}
}

# ===========================================================================================
# DATA SOURCES
# ===========================================================================================

data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.main.name
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ===========================================================================================
# 1. EKS CLUSTER
# ===========================================================================================

resource "aws_eks_cluster" "main" {
  name      = "${var.project_name}-${var.environment}-eks-cluster"
  version   = var.kubernetes_version
  role_arn  = var.cluster_role_arn

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    security_group_ids      = var.cluster_security_group_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = ["82.43.137.253/32"] #var.endpoint_public_access_cidrs
  }

  # Enable encryption for Kubernetes secrets
  encryption_config {
    provider {
      key_arn = var.kms_key_arn != "" ? var.kms_key_arn : aws_kms_key.eks[0].arn
    }
    resources = [ "secrets" ]
  }

  # Enable cluster logging
  enabled_cluster_log_types = var.cluster_log_types

  # Depends on IAM role being created first
  depends_on = [ var.cluster_role_arn ]

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-eks-cluster"
    Environment = var.environment
    Component   = "kubernetes"
    Service     = "control-plane"
  })
}

# ===========================================================================================
# 2. KMS KEY FOR SECRETS ENCRYPTION
# ===========================================================================================

resource "aws_kms_key" "eks" {
  count                     = var.kms_key_arn == "" ? 1 : 0

  description               = "EKS secrets encryption key for ${var.project_name}-${var.environment}"
  deletion_window_in_days   = 7
  enable_key_rotation       = true

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-eks-kms"
    Environment = var.environment
    Component   = "kubernetes"
  })
}

resource "aws_kms_alias" "eks" {
  count         = var.kms_key_arn == "" ? 1 : 0

  name          = "alias/${var.project_name}-${var.environment}-eks-key"
  target_key_id = aws_kms_key.eks[0].key_id
}

# ===========================================================================================
# 3. EKS MANAGED NODE GROUPS
# ===========================================================================================

resource "aws_eks_node_group" "main" {
  cluster_name      = aws_eks_cluster.main.name
  node_group_name   = "${var.project_name}-${var.environment}-node-group"
  node_role_arn     = var.node_role_arn
  subnet_ids        = var.private_subnet_ids

  # Instance configuration
  instance_types    = var.node_instance_types
  capacity_type     = var.node_capacity_type

  # Scaling configuration
  scaling_config {
    desired_size    = var.node_desired_size
    min_size        = var.node_min_size
    max_size        = var.node_max_size
  }

  # Update configuration
  update_config {
    max_unavailable = var.node_max_unavailable
  }

  # Remote access (SSH)
  dynamic "remote_access" {
    for_each = var.node_ssh_key_name != "" ? [1] : []
    content {
      ec2_ssh_key               = var.node_ssh_key_name
      source_security_group_ids = var.node_ssh_security_group_ids
    }
  }

  # Launch template configuration
  dynamic "launch_template" {
    for_each = var.launch_template_name != "" ? [1] : []
    content {
      name      = var.launch_template_name
      version   = var.launch_template_version
    }
  }

  # Node group lifecycle
  lifecycle {
    create_before_destroy = true
    ignore_changes = [ 
        scaling_config[0].desired_size    # Allow autoscaling to modify desired size
     ]
  }

  # Depends on cluster being ready
  depends_on = [ 
    aws_eks_cluster.main,
    var.node_role_arn
   ]

   tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-node-group"
    Environment = var.environment
    Component   = "kubernetes"
    Service     = "worker-node"
    "k8s.io/cluster-autoscaler/${var.project_name}-${var.environment}-eks-cluster" = "owned"
    "k8s.io/cluster-autoscaler/enabled" = "true"
  })
}

# ===========================================================================================
# 4. ADDITIONAL NODE GROUPS
# ===========================================================================================

# For specialized workloads (e.g., monitoring, data processing)
resource "aws_eks_node_group" "specialized" {
  count             = var.enable_specialized_node_group ? 1 : 0

  cluster_name      = aws_eks_cluster.main.name
  node_group_name   = "${var.project_name}-${var.environment}-specialized-node-group"
  node_role_arn     = var.node_role_arn
  subnet_ids        = var.private_subnet_ids
  instance_types    = var.specialized_instance_types
  capacity_type     = var.specialized_capacity_type
  
  scaling_config {
    desired_size    = var.specialized_desired_size
    min_size        = var.specialized_min_size
    max_size        = var.specialized_max_size
  }

  update_config {
    max_unavailable = var.specialized_max_unavailable
  }

  # Taints for specialized workloads
  taint {
    key     = "workload"
    value   = "specialized"
    effect  = "NO_SCHEDULE"
  }

  # Labels for node selection
  labels = {
    "workload-type" = "specialized"
    "managed-by"    = "terraform"
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-specialized-node-group"
    Environment = var.environment
    Component   = "kubernetes"
    Service     = "specialized-worker"
    "k8s.io/cluster-autoscaler/${var.project_name}-${var.environment}-eks-cluster" = "owned"
    "k8s.io/cluster-autoscaler/enabled" = "true"
  })

  depends_on = [ aws_eks_cluster.main ]
}

# ===========================================================================================
# 5. OIDC PROVIDER FOR IRSA
# ===========================================================================================

data "tls_certificate" "cluster" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "cluster" {
  count = var.create_oidc_provider ? 1 : 0

  client_id_list = [ "sts.amazonaws.com" ]
  thumbprint_list = [ data.tls_certificate.cluster.certificates[0].sha1_fingerprint ]
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-iodc-provider"
    Environment = var.environment
    Component   = "kubernetes"
    Service     = "oidc"
  })
}

# ===========================================================================================
# 6. CLUSTER ADD-ONS
# ===========================================================================================

# VPC-CNI (Networking)
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.main.name
  addon_name = "vpc-cni"
  addon_version = var.vpc_cni_version
  resolve_conflicts_on_create = "OVERWRITE"

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-vpc-cni"
    Environment = var.environment
    Component   = "kubernetes"
    Service     = "addon"
  })
}

# CoreDNS
resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.main.name
  addon_name = "coredns"
  addon_version = var.coredns_version
  resolve_conflicts_on_create = "OVERWRITE"

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-coredns"
    Environment = var.environment
    Component   = "kubernetes"
    Service     = "addon"
  })
}

# Kube-Proxy
resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.main.name
  addon_name = "kube-proxy"
  addon_version = var.kube_proxy_version
  resolve_conflicts_on_create = "OVERWRITE"

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-kube-proxy"
    Environment = var.environment
    Component   = "kubernetes"
    Service     = "addon"
  })
}

# AWS Load Balancer controller
resource "aws_eks_addon" "lb_controller" {
  count = var.enable_lb_controller ? 1 : 0

  cluster_name = aws_eks_cluster.main.name
  addon_name = "aws-load-balancer-controller"
  addon_version = var.lb_controller_version
  resolve_conflicts_on_create = "OVERWRITE"

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-lb-controller"
    Environment = var.environment
    Component   = "kubernetes"
    Service     = "addon"
  })
}

