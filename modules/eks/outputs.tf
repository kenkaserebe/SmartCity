# ==============================================================================
# EKS Module - Outputs
# ==============================================================================


# ==============================================================================
# CLUSTER INFORMATION
# ==============================================================================
output "cluster_id" {
  description = "ID of the EKS cluster"
  value = aws_eks_cluster.main.id
}

output "cluster_name" {
  description = "Name of the EKS cluster"
  value = aws_eks_cluster.main.name
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "API server endpoint of the EKS cluster"
  value = aws_eks_cluster.main.endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID of the EKS cluster"
  value = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate authority data of the EKS cluster"
  value = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_identity_oidc_issuer" {
  description = "OIDC issuer URL of the EKS cluster"
  value = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "cluster_version" {
  description = "Kubernetes version of the EKS cluster"
  value = aws_eks_cluster.main.version
}


# ==============================================================================
# OIDC PROVIDER
# ==============================================================================

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider"
  value = try(aws_iam_openid_connect_provider.cluster[0].arn, null)
}

output "oidc_provider_url" {
  description = "URL of the OIDC provider"
  value = try(aws_iam_openid_connect_provider.cluster[0].url, null)
}


# ==============================================================================
# NODE GROUP INFORMATION
# ==============================================================================

output "node_group_id" {
  description = "ID of the main EKS node group"
  value = aws_eks_node_group.main.id
}

output "node_group_arn" {
  description = "ARN of the main EKS node group"
  value = aws_eks_node_group.main.arn
}

output "node_group_status" {
  description = "Status of the main EKS node group"
  value = aws_eks_node_group.main.status
}

output "specialized_node_group_id" {
  description = "ID of the specialized EKS node group"
  value = try(aws_eks_node_group.specialized[0].id, null)
}


# ==============================================================================
# KMS KEY INFORMATION
# ==============================================================================

output "kms_key_arn" {
  description = "ARN of the KMS key used for secrets encryption"
  value = try(aws_kms_key.eks[0].arn, var.kms_key_arn)
}

output "kms_key_id" {
  description = "ID of the KMS key used for secrets encryption"
  value = try(aws_kms_key.eks[0].key_id, var.kms_key_arn)
}


# ==============================================================================
# AUTHENTICATION
# ==============================================================================

output "cluster_auth_token" {
  description = "Authentication token for the EKS cluster"
  value = data.aws_eks_cluster_auth.cluster.token
  sensitive = true
}


# ==============================================================================
# KUBECONFIG
# ==============================================================================

output "kubeconfig" {
  description = "Kubeconfig for the EKS cluster"
  value = {
    apiVersion = "v1"
    clusters = [{
        cluster = {
            server = aws_eks_cluster.main.endpoint
            certificate-authority-data = aws_eks_cluster.main.certificate_authority[0].data
        }
        name = aws_eks_cluster.main.name
    }]
    context = [{
        context = {
            cluster = aws_eks_cluster.main.name
            user = aws_eks_cluster.main.name
        }
        name = aws_eks_cluster.main.name
    }]
    current-context = aws_eks_cluster.main.name
    kind = "Config"
    preferences = {}
    users = [{
        name = aws_eks_cluster.main.name
        user = {
            exec = {
                apiVersion = "client.authentication.k8s.io/v1beta1"
                command = "aws"
                args = [
                    "eks",
                    "get-token",
                    "--cluster-name",
                    aws_eks_cluster.main.name,
                    "--region",
                    data.aws_region.current.name
                ]
                interactiveMode = "Never"
            }
        }
    }]
  }
  sensitive = true
}


# ==============================================================================
# SUMMARY
# ==============================================================================

output "eks_summary" {
  description = "Summary of EKS resources"
  value = {
    cluster_name = aws_eks_cluster.main.name
    cluster_endpoint = aws_eks_cluster.main.endpoint
    cluster_version = aws_eks_cluster.main.version
    node_group_name = aws_eks_node_group.main.node_group_name
    node_group_desired = var.node_desired_size
    node_group_min = var.node_min_size
    node_group_max = var.node_max_size
    oidc_provider = try(aws_iam_openid_connect_provider.cluster[0].arn, null)
    specialized_enabled = var.enable_specialized_node_group
  }
}


# ==============================================================================
# AWS LOAD BALANCER CONTROLLER
# ==============================================================================

output "lb_controller_enabled" {
  description = "Whether the AWS Load Balancer Controller add-on is enabled"
  value = var.enable_lb_controller
}