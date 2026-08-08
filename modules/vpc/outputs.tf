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
output "public_subnets" {
  description = "Map of AZ => public subnet IDs"
  value = {
    for az, subnet in aws_subnet.public : az => subnet.id 
  }
}

output "private_subnets" {
  description = "Map of AZ => private subnet IDs"
  value = {
    for az, subnet in aws_subnet.private : az => subnet.id
  }
}

output "database_subnets" {
    description = "Map of AZ => database subnet IDs"
    value = {
        for az, subnet in aws_subnet.database : az => subnet.id
  }
}

output "public_subnet_cidrs" {
  description = "Map of AZ => public subnet CIDRs"
  value = {
    for az, subnet in aws_subnet.public : az => subnet.cidr_block
  }
}

output "private_subnet_cidrs" {
  description = "Map of AZ => private subnet CIDRs"
  value = {
    for az, subnet in aws_subnet.private : az => subnet.cidr_block
  }
}

output "database_subnet_cidrs" {
  description = "Map of AZ => database subnet CIDRs"
  value = {
    for az, subnet in aws_subnet.database : az => subnet.cidr_block
  }
}

# =====================================================================
# NAT GATEWAYS OUTPUTS
# =====================================================================
output "nat_gateway_ids" {
  description = "nat gateway IDs"
  value = {
    for az, nat in aws_nat_gateway.main : az => nat.id
  }
}

# ==========================================================================================
# ROUTE TABLE OUTPUTS
# ==========================================================================================
output "private_route_tables" {
  description = "IDs of the private route tables"
  value = {
    for az, rt in aws_route_table.private : az => rt.id
  }
}

output "database_route_tables" {
  description = "IDs of the database route tables"
  value = {
    for az, rt in aws_route_table.database : az => rt.id
  }
}

# ==========================================================================================
# AVAILABILITY ZONE OUTPUTS
# ==========================================================================================
output "availability_zones" {
  description   = "List of availability zones used"
  value         = keys(var.subnets)
}