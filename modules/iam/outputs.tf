# ===========================================================================================
# IAM Module - Outputs
# ===========================================================================================

# ===========================================================================================
# EKS CLUSTER ROLES
# ===========================================================================================

output "eks_cluster_role_arn" {
  description   = "ARN of the EKS cluster role"
  value         = aws_iam_role.eks_cluster.arn
}

output "eks_cluster_role_name" {
  description   = "Name of the EKS cluster role"
  value         = aws_iam_role.eks_cluster.name
}

# ===========================================================================================
# EKS NODE ROLES
# ===========================================================================================

output "eks_node_role_arn" {
  description   = "ARN of the EKS node role"
  value         = aws_iam_role.eks_node.arn
}

output "eks_node_role_name" {
  description   = "Name of the EKS node role"
  value         = aws_iam_role.eks_node.name
}

output "eks_node_instance_profile_name" {
  description   = "Name of the EKS node instance profile"
  value         = aws_iam_instance_profile.eks_node.name
}

output "eks_node_instance_profile_arn" {
  description   = "ARN of the EKS node instance profile"
  value         = aws_iam_instance_profile.eks_node.arn
}

# ===========================================================================================
# OIDC PROVIDER
# ===========================================================================================

output "oidc_provider_arn" {
  description   = "ARN of the OIDC provider"
  value         = var.create_oidc_provider ? aws_iam_openid_connect_provider.cluster[0].arn : null    #try(aws_iam_openid_connect_provider.cluster[0].arn, null)
}

output "oidc_provider_url" {
  description   = "URL of the OIDC provider"
  value         = try(aws_iam_openid_connect_provider.cluster[0].url, null)
}

# ===========================================================================================
# IRSA ROLES
# ===========================================================================================

output "app_s3_role_arn" {
  description   = "ARN of the S3 IRSA role"
  value         = try(aws_iam_role.app_s3[0].arn, null)
}

output "app_sqs_role_arn" {
  description   = "ARN of the SQS IRSA role"
  value         = try(aws_iam_role.app_sqs[0].arn, null)
}

output "app_rds_role_arn" {
  description   = "ARN of the RDS IRSA role"
  value         = try(aws_iam_role.app_rds[0].arn, null)
}

# ===========================================================================================
# POLICY ARNS
# ===========================================================================================

output "s3_policy_arn" {
  description   = "ARN of the S3 access policy"
  value         = try(aws_iam_policy.s3_access[0].arn, null)
}

output "sqs_policy_arn" {
  description   = "ARN of the SQS access policy"
  value         = try(aws_iam_policy.sqs_access[0].arn, null)
}

output "rds_policy_arn" {
  description   = "ARN of the RDS access policy"
  value         = try(aws_iam_policy.rds_access[0].arn, null)
}

# ===========================================================================================
# SUMMARY
# ===========================================================================================

output "iam_summary" {
  description   = "Summary of IAM resources created"
  value         = {
    eks_cluster_role    = aws_iam_role.eks_cluster.name
    eks_node_role       = aws_iam_role.eks_node.name
    oidc_provider       = try(aws_iam_openid_connect_provider.cluster[0].arn, null)
    s3_access           = var.enable_s3_access
    sqs_access          = var.enable_sqs_access
    rds_access          = var.enable_rds_access
  }
}