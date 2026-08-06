# ========================================================================
# Security Groups Module - Outputs
# ========================================================================

# ========================================================================
# SECURITY GROUP IDS
# ========================================================================
output "bastion_sg_id" {
  description = "ID of the bastion security group"
  value = aws_security_group.bastion.id
}

output "load_balancer_sg_id" {
  description = "ID of the load balancer security group"
  value = aws_security_group.load_balancer.id
}

output "application_sg_id" {
  description = "ID of the application security group"
  value = aws_security_group.application.id
}

output "database_sg_id" {
  description = "ID of the database security group"
  value = aws_security_group.database.id
}

output "cache_sg_id" {
  description = "ID of the cache/Redis security group"
  value = try(aws_security_group.cache[0].id, null)
}

output "eks_cluster_sg_id" {
  description = "ID of the EKS cluster security group"
  value = aws_security_group.eks_cluster.id
}

output "eks_node_sg_id" {
  description = "ID of the EKS node security group"
  value = aws_security_group.eks_node.id
}

output "monitoring_sg_id" {
  description = "ID of the monitoring security group"
  value = try(aws_security_group.monitoring[0].id, null)
}


# =========================================================================
# SECURITY GROUP ARNs
# =========================================================================
output "bastion_sg_arn" {
  description = "ARN of the bastion security group"
  value = aws_security_group.bastion.arn
}

output "load_balancer_sg_arn" {
  description = "ARN of the load balancer security group"
  value = aws_security_group.load_balancer.arn
}

output "application_sg_arn" {
  description = "ARN of the application security group"
  value = aws_security_group.application.arn
}

output "database_sg_arn" {
  description = "ARN of the database security group"
  value = aws_security_group.database.arn
}


# ============================================================================
# SUMMARY OUTPUT
# ============================================================================
output "security_groups_summary" {
  description = "Summary of all security groups created"
  value = {
    bastion = aws_security_group.bastion.id
    load_balancer = aws_security_group.load_balancer.id
    application = aws_security_group.application.id
    database = aws_security_group.database.id
    cache = try(aws_security_group.cache[0].id, null)
    eks_cluster = aws_security_group.eks_cluster.id
    eks_node = aws_security_group.eks_node.id
    monitoring = try(aws_security_group.monitoring[0].id, null)
  }
}