terraform {
  backend "s3" {}
}


# ===========================================================================================
# IAM Module - SmartCity IoT Platform
# ===========================================================================================
# Creates all IAM roles, policies, and attachments needed for:
# - EKS Cluster
# - EKS Node Groups
# - RDS Database
# - S3 Access
# - SQS Access
# - Application Service Accounts (IRSA)
# ===========================================================================================

# ===========================================================================================
# 1. EKS CLUSTER ROLE
# ===========================================================================================
# The cluster role allows EKS to manage AWS resources on your behalf
# ===========================================================================================

resource "aws_iam_role" "eks_cluster" {
  name = "${var.project_name}-${var.environment}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version     = "2012-10-17"
    Statement   = [{
        Effect      = "Allow"
        Principal   = {
            Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
    }]
  })

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-eks-cluster-role"
    Environment = var.environment
    Component   = "iam"
    Service     = "eks-cluster"
  })
}

# EKS Cluster Policy - Required for cluster management
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn    = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role          = aws_iam_role.eks_cluster.name
}

# EKS VPC Resource Controller - Required for VPC management
resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  policy_arn    = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role          = aws_iam_role.eks_cluster.name
}

# EKS Compute Policy - For EC2 operations
resource "aws_iam_role_policy_attachment" "eks_compute_policy" {
  policy_arn    = "arn:aws:iam::aws:policy/AmazonEKSComputePolicy"
  role          = aws_iam_role.eks_cluster.name
}

# ===========================================================================================
# 2. EKS NODE GROUP ROLE
# ===========================================================================================
# The node role gives worker nodes permissions to join the cluster and access AWS services
# ===========================================================================================
resource "aws_iam_role" "eks_node" {
  name  = "${var.project_name}-${var.environment}-eks-node-role"

  assume_role_policy = jsonencode({
    Version     = "2012-10-17"
    Statement   = [{
        Effect      = "Allow"
        Principal   = {
            Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
    }]
  })

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-eks-node-role"
    Environment = var.environment
    Component   = "iam"
    Service     = "eks-node"
  })
}

# EKS Worker Node Policy - Required for nodes to join cluster
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn    = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role          = aws_iam_role.eks_node.name
}

# EKS CNI Policy - Required for network management
resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn    = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role          = aws_iam_role.eks_node.name
}

# ECR Pull Policy - Allows nodes to pull container images
resource "aws_iam_role_policy_attachment" "ecr_pull_policy" {
  policy_arn    = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role          = aws_iam_role.eks_node.name
}

# S3 Policy - For nodes to access S3 buckets (optional)
resource "aws_iam_role_policy_attachment" "s3_policy" {
  count         = var.enable_s3_access ? 1 : 0

  policy_arn    = aws_iam_policy.s3_access[0].arn
  role          = aws_iam_role.eks_node.name
}

# SQS Policy - For nodes to access SQS queues (optional)
resource "aws_iam_role_policy_attachment" "sqs_policy" {
  count         = var.enable_sqs_access ? 1 : 0

  policy_arn    = aws_iam_policy.sqs_access[0].arn
  role          = aws_iam_role.eks_node.name
}

# CloudWatch Logs Policy - For node logging
resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
  policy_arn    = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  role          = aws_iam_role.eks_node.name
}

# SSM Policy - For node management (optional)
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  count         = var.enable_ssm_access ? 1 : 0

  policy_arn    = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role          = aws_iam_role.eks_node.name
}


# ==========================================================================================
# 3. EKS NODE INSTANCE PROFILE
# ==========================================================================================
# Required for EC2 instances to assume the node role
# ==========================================================================================
resource "aws_iam_instance_profile" "eks_node" {
  name = "${var.project_name}-${var.environment}-eks-node-instance-profile"
  role = aws_iam_role.eks_node.name

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-eks-node-instance-profile"
    Environment = var.environment
    Component   = "iam"
    Service     = "eks-node"
  })
}


# ==========================================================================================
# 4. OIDC PROVIDER FOR IRSA
# ==========================================================================================
# Allows Kubernetes service accounts to assume IAM roles.
# This is created by EKS, but we define the data source here
# ==========================================================================================
data "aws_eks_cluster" "cluster" {
  count = var.create_oidc_provider ? 1 : 0

  name  = "${var.project_name}-${var.environment}-eks-cluster"
}

data "tls_certificate" "cluster" {
  count = var.create_oidc_provider ? 1 : 0

  url   = data.aws_eks_cluster.cluster[0].identity[0].oidc[0].issuer
}

# OIDC Provider for the cluster
resource "aws_iam_openid_connect_provider" "cluster" {
  count             = var.create_oidc_provider ? 1 : 0

  client_id_list    = ["sts.amazonaws.com"]
  thumbprint_list   = [data.tls_certificate.cluster[0].certificates[0].sha1_fingerprint]
  url               = data.aws_eks_cluster.cluster[0].identity[0].oidc[0].issuer

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-oidc-provider"
    Environment = var.environment
    Component   = "iam"
    Service     = "oidc"
  })
}


# ============================================================================================
# 5. IRSA ROLES FOR KUBERNETES SERVICE ACCOUNTS
# ============================================================================================
# Each service account gets its own IAM role with specific permissions
# ============================================================================================

# 5a. S3 Access Role for Application
resource "aws_iam_role" "app_s3" {
  count = var.enable_s3_access ? 1 : 0

  name = "${var.project_name}-${var.environment}-app-s3-role"

  assume_role_policy = var.create_oidc_provider ? jsonencode({
    Version = "2012-10-17"
    Statement = [{
        Effect = "Allow"
        Principal = {
            Federated = aws_iam_openid_connect_provider.cluster[0].arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
            StringEquals = {
                "${data.aws_eks_cluster.cluster[0].identity[0].oidc[0].issuer}:sub" = "system:serviceaccount:${var.namespace}:s3-access"
            }
        }
    }]
  }) : jsonencode({})

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-app-s3-role"
    Environment = var.environment
    Component   = "iam"
    Service     = "s3-access"
  })
}

resource "aws_iam_policy" "s3_access" {
  count = var.enable_s3_access ? 1 : 0

  name = "${var.project_name}-${var.environment}-s3-access-policy"
  description = "S3 bucket access policy for Smartcity application"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Effect = "Allow"
            Action = [
                "s3:GetObject",
                "s3;PutObject",
                "s3:DeleteObject",
                "s3:ListObject",
                "s3:GetBucketLocation"
            ]
            Resource = [
                "arn:aws:s3:::${var.s3_bucket_name}",
                "arn:aws:s3:::${var.s3_bucket_name}/*"
            ]
        }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "app_s3" {
  count = var.enable_s3_access ? 1 : 0

  policy_arn = aws_iam_policy.s3_access[0].arn
  role = aws_iam_role.app_s3[0].name
}

# 5b. SQS Access Role for Application
resource "aws_iam_role" "app_sqs" {
  count = var.enable_sqs_access ? 1 : 0

  name = "${var.project_name}-${var.environment}-app-sqs-role"

  assume_role_policy = var.create_oidc_provider ? jsonencode({
    Version = "2012-10-17"
    Statement = [{
        Effect = "Allow"
        Principal = {
            Federated = aws_iam_openid_connect_provider.cluster[0].arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
            StringEquals = {
                "${data.aws_eks_cluster.cluster[0].identity[0].oidc[0].issuer}:sub" = "system:serviceaccount:${var.namespace}:sqs-access"
            }
        }
    }]
  }) : jsonencode({})

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-app-sqs-role"
    Environment = var.environment
    Component   = "iam"
    Service     = "sqs-access"
  })  
}

resource "aws_iam_policy" "sqs_access" {
  count = var.enable_sqs_access ? 1 : 0

  name = "${var.project_name}-${var.environment}-sqs-access-policy"
  description = "SQS queue access policy for SmartCity application"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Effect = "Allow"
            Action = [
                "sqs:SendMessage",
                "sqs:ReceiveMessage",
                "sqs:DeleteMessage",
                "sqs:GetQueueAttributes",
                "sqs:GetQueueUrl",
                "sqs:ListQueues"
            ]
            Resource = [
                "arn:aws:sqs:${var.region}:${data.aws_caller_identity.current.account_id}:${var.sqs_queue_name}",
                "arn:aws:sqs:${var.region}:${data.aws_caller_identity.current.account_id}:${var.sqs_dlq_name}"
            ]
        }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "app_sqs" {
  count = var.enable_sqs_access ? 1 : 0

  policy_arn = aws_iam_policy.sqs_access[0].arn
  role = aws_iam_role.app_sqs[0].name
}

# 5c. RDS Access Role for Application
resource "aws_iam_role" "app_rds" {
  count = var.enable_rds_access ? 1 : 0

  name = "${var.project_name}-${var.environment}-app-rds-role"

  assume_role_policy = var.create_oidc_provider ? jsonencode({
    Version = "2012-10-17"
    Statement = [{
        Effect = "Allow"
        Principal = {
            Federated = aws_iam_openid_connect_provider.cluster[0].arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
            StringEquals = {
                "${data.aws_eks_cluster.cluster[0].identity[0].oidc[0].issuer}:sub" = "system:serviceaccount:${var.namespace}:rds-access"
            }
        }
    }]
  }) : jsonencode({})

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-app-rds-role"
    Environment = var.environment
    Component   = "iam"
    Service     = "rds-access"
  })
}

# RDS IAM Authentication Policy
resource "aws_iam_policy" "rds_access" {
  count = var.enable_rds_access ? 1 : 0

  name = "${var.project_name}-${var.environment}-rds-access-policy"
  description = "RDS IAM authentication access policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Effect = "Allow"
            Action = [
                "rds-db:connect"
            ]
            Resource = [
                "arn:aws:rds-db:${var.region}:${data.aws_caller_identity.current.account_id}:dbuser:${var.rds_resource_id}/${var.rds_username}"
            ]
        }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "app_rds" {
  count = var.enable_rds_access ? 1 : 0

  policy_arn = aws_iam_policy.rds_access[0].arn
  role = aws_iam_role.app_rds[0].name
}


# ==================================================================================================================
# 6. DATA SOURCES
# ==================================================================================================================

data "aws_caller_identity" "current" {
  
}