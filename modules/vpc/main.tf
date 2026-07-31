# SmartCity/modules/vpc/main.tf

terraform {
  backend "s3" {}
}

# ======================================================================
# VPC
# ======================================================================
resource "aws_vpc" "main" {
  cidr_block            = var.vpc_cidr
  enable_dns_support    = true
  enable_dns_hostnames  = true
  instance_tenancy      = "default"

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-vpc"
    Environment = var.environment
    Component   = "networking"
  })
}


# ======================================================================
# INTERNET GATEWAY
# ======================================================================
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-igw"
    Environment = var.environment
    Component   = "networking"
  })
}


# ======================================================================
# PUBLIC SUBNETS
# ======================================================================
resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  # Public subnets automatically assign public IPs to launched instances
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-public-${count.index + 1}"

    Environment = var.environment
    Component   = "networking"
    Tier        = "public"
    AZ          = var.availability_zones[count.index]
  })
}


# =======================================================================
# PRIVATE SUBNETS
# =======================================================================
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = false

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-private-${count.index + 1}"
    Environment = var.environment
    Component   = "networking"
    Tier        = "private"
    AZ          = var.availability_zones[count.index]
  })
}


# ==============================================================================
# DATABASE SUBNETS
# ==============================================================================
resource "aws_subnet" "database" {
  count                     = length(var.database_subnet_cidrs)

  vpc_id                    = aws_vpc.main.id
  cidr_block                = var.database_subnet_cidrs[count.index]
  availability_zone         = var.availability_zones[count.index]

  map_public_ip_on_launch   = false

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-database-${count.index + 1}"
    Environment = var.environment
    Component   = "networking"
    Tier        = "database"
    AZ          = var.availability_zones[count.index]
  })
}


# =================================================================================
# PUBLIC ROUTE TABLE
# =================================================================================
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-public-rt"
    Environment = var.environment
    Component   = "networking"
    Tier        = "public"
  })
}


# ==================================================================================
# PUBLIC ROUTE TABLE ASSOCIATIONS
# ==================================================================================
resource "aws_route_table_association" "public" {
  count             = length(var.public_subnet_cidrs)
  subnet_id         = aws_subnet.public[count.index].id
  route_table_id    = aws_route_table.public.id
}


# ==================================================================================
# ELASTIC IP ADDRESSES FOR NAT GATEWAYS
# ==================================================================================
resource "aws_eip" "nat" {
  count     = var.enable_nat_gateway ? length(var.public_subnet_cidrs) : 0

  domain    = "vpc"

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-nat-eip-${count.index + 1}"
    Environment = var.environment
    Component   = "networking"
  })
}


# =================================================================================
# NAT GATEWAYS
# =================================================================================
resource "aws_nat_gateway" "main" {
  count         = var.enable_nat_gateway ? length(var.public_subnet_cidrs) : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_eip.nat[count.index].id

  # Ensure NAT gateway is created after Internet Gateway
  # (Internet Gateway is required for NAT gateway to route traffic)
  depends_on = [ aws_internet_gateway.main ]

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-nat-{count.index + 1}"
    Environment = var.environment
    Component   = "networking"
  })
}


# ==================================================================================
# PRIVATE ROUTE TABLES
# ==================================================================================
# One route table per private subnet, each routing through its AZ's NAT gateway.
# This creates AZ-level isolation - traffic from private subnet in AZ-A
# exits through the NAT gateway in AZ-A's public subnet
# ==================================================================================
resource "aws_route_table" "private" {
  count     = length(aws_subnet.private)

  vpc_id    = aws_vpc.main.id

  # route {
  #   cidr_block      = "0.0.0.0/0"
  #   nat_gateway_id  = aws_nat_gateway.main[count.index].id
  # }
  

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-private-rt-${count.index + 1}"
    Environment = var.environment
    Component   = "networking"
    Tier        = "private"
  })
}

resource "aws_route" "private_nat" {
  count                   = length(aws_route_table.private)
  route_table_id          = aws_route_table.private[count.index].id
  destination_cidr_block  = "0.0.0.0/0"
  nat_gateway_id          = aws_nat_gateway.main[count.index].id
}

# ======================================================================================
# PRIVATE ROUTE TABLE ASSOCIATIONS
# ======================================================================================
resource "aws_route_table_association" "private" {
  count             = length(var.private_subnet_cidrs)

  subnet_id         = aws_subnet.private[count.index].id
  route_table_id    = var.enable_nat_gateway ? aws_route_table.private[count.index].id : aws_route_table.public.id
}


# =====================================================================================
# DATABASE ROUTE TABLES
# =====================================================================================
# Database subnets follow the same routing pattern as private subnets
# They get internet access via NAT gateway if enabled
# =====================================================================================
resource "aws_route_table" "database" {
  count     = var.enable_nat_gateway ? length(var.database_subnet_cidrs) : 0

  vpc_id    = aws_vpc.main.id

  route {
    cidr_block      = "0.0.0.0/0"
    nat_gateway_id  = aws_nat_gateway.main[count.index % length(aws_nat_gateway.main)].id
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-database-rt-${count.index + 1}"
    Environment = var.environment
    Component   = "networking"
    Tier        = "database"
  })
}

resource "aws_route_table_association" "database" {
  count             = length(var.database_subnet_cidrs)
  subnet_id         = aws_subnet.database[count.index].id
  route_table_id    = var.enable_nat_gateway ? aws_route_table.database[count.index].id : aws_route_table.public.id
}


# ====================================================================================================
# VPC FLOW LOGS (FOR AUDIT/COMPLIANCE)
# ====================================================================================================
resource "aws_flow_log" "vpc_flow_log" {
  count                 = var.enable_flow_logs ? 1 : 0

  log_destination       = aws_s3_bucket.flow_logs[0].arn
  log_destination_type  = "s3"
  traffic_type          = "ALL"
  vpc_id                = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-vpc-flow-log"
    Environment = var.environment
    Component   = "monitoring"
  })
}


# Flow logs bucket (only created if flow logs enabled)
resource "aws_s3_bucket" "flow_logs" {
  count         = var.enable_flow_logs ? 1 : 0

  bucket        = "${var.project_name}-${var.environment}-vpc-flow-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-vpc-flow-logs"
    Environment = var.environment
    Component   = "monitoring"
  })
}


resource "aws_s3_bucket_public_access_block" "flow_logs" {
  count                     = var.enable_flow_logs ? 1 : 0

  bucket                    = aws_s3_bucket.flow_logs[0].id

  block_public_acls         = true
  block_public_policy       = true
  ignore_public_acls        = true
  restrict_public_buckets   = true
}


resource "aws_s3_bucket_lifecycle_configuration" "flow_logs" {
  count   = var.enable_flow_logs ? 1 : 0

  bucket  = aws_s3_bucket.flow_logs[0].id

  rule {
    id      = "expire-old-logs"
    status  = "Enabled"

    expiration {
      days = var.flow_logs_retention_days
    }
  }
}


# ============================================================================================
# DATA SOURCES
# ============================================================================================
data "aws_caller_identity" "current" {}


# ============================================================================================
# DEFAULT SECURITY GROUP (Optional override)
# ============================================================================================
# By default, AWS creates a default SG with allow-all-outbound and no inbound rules. We can
# keep it or replace it. This module leaves it alone - no need to manage it here. 
# ============================================================================================

# ============================================================================================
# TAGS
# ============================================================================================
# All resources get tags from var.common_tags plus resource-specific tags.
# Common tags all you to track costs, owners and environments across all your AWS resources.
# ============================================================================================