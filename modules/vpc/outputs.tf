# SmartCity/modules/vpc/outputs.tf

# ==================================================================================
# VPC Module - Outputs
# ==================================================================================
# All outputs needed by other modules (security groups, EKS, RDS, etc.)
# ==================================================================================

# ==================================================================================
# VPC OUTPUTS
# ==================================================================================
output "vpc_id" {
  description   = "ID of the VPC"
  value         = aws_vpc.main.id
}

output "vpc_cidr" {
  description   = "CIDR block of the VPC"
  value         = aws_vpc.main.cidr_block
}

output "vpc_arn" {
  description   = "ARN of the VPC"
  value         = aws_vpc.main.arn
}


# ==================================================================================
# SUBNET OUTPUTS
# ==================================================================================
output "public_subnet_ids" {
  description   = "IDs of public subnets"
  value         = aws_subnet.public[*].id
}

output "public_subnet_cidrs" {
  description   = "CIDR blocks of public subnets"
  value         = aws_subnet.public[*].cidr_block
}

output "private_subnet_ids" {
  description   = "IDs of private subnets"
  value         = aws_subnet.private[*].id
}

output "private_subnet_cidrs" {
  description   = "CIDR blocks of private subnets"
  value         = aws_subnet.private[*].cidr_block
}

output "database_subnet_ids" {
  description   = "IDs of database subnets"
  value         = aws_subnet.database[*].id
}

output "database_subnet_cidrs" {
  description   = "CIDR blocks of database subnets"
  value         = aws_subnet.database[*].cidr_block
}


# ==========================================================================================
# ROUTE TABLE OUTPUTS
# ==========================================================================================
output "public_route_table_id" {
  description   = "ID of the public route table"
  value         = aws_route_table.public.id
}

output "private_route_table_id" {
  description   = "IDs of the private route tables"
  value         = aws_route_table.private[*].id
}

output "database_route_table_id" {
  description   = "IDs of the database route tables"
  value         = aws_route_table.database[*].id
}


# ==========================================================================================
# GATEWAY OUTPUTS
# ==========================================================================================
output "internet_gateway_id" {
  description   = "ID of the internet gateway"
  value         = aws_internet_gateway.main.id
}

output "nat_gateway_ids" {
  description   = "IDs of NAT gateways"
  value         = aws_nat_gateway.main[*].id
}

output "nat_gateway_public_ips" {
  description   = "Public IP addresses of NAT gateways"
  value         = aws_eip.nat[*].public_ip
}


# ==========================================================================================
# AVAILABILITY ZONE OUTPUTS
# ==========================================================================================
output "availability_zones" {
  description   = "List of availability zones used"
  value         = var.availability_zones
}


# ===========================================================================================
# FLOW LOG OUTPUTS
# ===========================================================================================
output "flow_log_id" {
  description   = "ID of the VPC flow log (if enabled)"
  value         = try(aws_flow_log.vpc_flow_log[0].id, null)
}

output "flow_log_bucket_arn" {
  description   = "ARN of the flow log S3 bucket (if enabled)"
  value         = try(aws_s3_bucket.flow_logs[0].arn, null)
}


# ============================================================================================
# SUMMARY OUTPUTS (Useful for debugging and monitoring)
# ============================================================================================
output "vpc_summary" {
  description   = "Summary of the VPC configuration"
  value = {
    vpc_id            = aws_vpc.main.id
    vpc_cidr          = aws_vpc.main.cidr_block
    environment       = var.environment
    region            = var.region
    public_subnets    = length(aws_subnet.public)
    private_subnets   = length(aws_subnet.private)
    database_subnets  = length(aws_subnet.database)
    nat_gateways      = length(aws_nat_gateway.main)
    flow_logs_enabled = var.enable_flow_logs
  }
}


# =============================================================================================
# DATABASE SUBNET GROUP (Convenience output for RDS)
# =============================================================================================
output "database_subnet_group_name" {
  description   = "Name of the databes subnet group (use this for RDS/Aurora)"
  value         = "${var.project_name}-${var.environment}-db-subnet-group"
}


# =============================================================================================
# SECURITY GROUP REFERENCE OUTPUTS
# =============================================================================================
output "vpc_default_security_group_id" {
  description   = "ID of the default security group in the VPC (use with caution)"
  value         = aws_vpc.main.default_security_group_id
}


# =============================================================================================
# VPC PEERING OUTPUTS (For future expansion)
# =============================================================================================
output "vpc_owner_id" {
  description   = "AWS account ID that owns the VPC"
  value         = data.aws_caller_identity.current.account_id
}