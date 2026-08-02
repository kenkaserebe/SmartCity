# SmartCity/modules/vpc/main.tf

terraform {
  backend "s3" {}
}

locals {
  az_map = {
    for idx, az in var.availability_zones : az => {
      public_cidr   = var.public_subnet_cidrs[idx]
      private_cidr  = var.private_subnet_cidrs[idx]
      database_cidr = var.database_subnet_cidrs[idx]
    }
  }
}

# ======================================================================
# VPC
# ======================================================================
resource "aws_vpc" "main" {
  cidr_block            = var.vpc_cidr
  enable_dns_support    = var.enable_dns_support
  enable_dns_hostnames  = var.enable_dns_hostname
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
  for_each          = local.az_map

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.public_cidr
  availability_zone = each.key

  # Public subnets automatically assign public IPs to launched instances
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-public-${each.key}"

    Environment = var.environment
    Component   = "networking"
    Tier        = "public"
  })
}


# =======================================================================
# PRIVATE SUBNETS
# =======================================================================
resource "aws_subnet" "private" {
  for_each          = local.az_map

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.private_cidr
  availability_zone = each.key

  map_public_ip_on_launch = false

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-private-${each.key}"
    Environment = var.environment
    Component   = "networking"
    Tier        = "private"
  })
}


# ==============================================================================
# DATABASE SUBNETS
# ==============================================================================
resource "aws_subnet" "database" {
  for_each                  = local.az_map
  vpc_id                    = aws_vpc.main.id
  cidr_block                = each.value.database_cidr
  availability_zone         = each.key

  map_public_ip_on_launch   = false

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-database-${each.key}"
    Environment = var.environment
    Component   = "networking"
    Tier        = "database"
  })
}


# =================================================================================
# PUBLIC ROUTE TABLE
# =================================================================================
resource "aws_route_table" "public" {
  vpc_id  = aws_vpc.main.id

  tags    = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-public-rt"
    Environment = var.environment
    Component   = "networking"
    Tier        = "public"
  })
}


# ==================================================================================
# PUBLIC ROUTE
# ==================================================================================
resource "aws_route" "public_internet" {
  route_table_id          = aws_route_table.public.id
  destination_cidr_block  = "0.0.0.0/0"
  gateway_id              = aws_internet_gateway.main.id
}

# ==================================================================================
# PUBLIC ROUTE TABLE ASSOCIATIONS
# ==================================================================================
resource "aws_route_table_association" "public" {
  for_each          = local.az_map
  subnet_id         = aws_subnet.public[each.key].id
  route_table_id    = aws_route_table.public.id
}


# ==================================================================================
# ELASTIC IP ADDRESSES FOR NAT GATEWAYS
# ==================================================================================
resource "aws_eip" "nat" {
  for_each  = var.enable_nat_gateway ? local.az_map : {}

  domain    = "vpc"

  tags      = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-nat-eip-${each.key}"
    Environment = var.environment
    Component   = "networking"
  })
}


# =================================================================================
# NAT GATEWAYS
# =================================================================================
resource "aws_nat_gateway" "main" {
  for_each = var.enable_nat_gateway ? local.az_map : {}

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  # Ensure NAT gateway is created after Internet Gateway
  # (Internet Gateway is required for NAT gateway to route traffic)
  depends_on = [ aws_internet_gateway.main ]

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-nat-${each.key}"
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
  for_each  = local.az_map

  vpc_id    = aws_vpc.main.id  

  tags      = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-private-rt-${each.key}"
    Environment = var.environment
    Component   = "networking"
    Tier        = "private"
  })
}

resource "aws_route" "private_nat" {
  for_each                = var.enable_nat_gateway ? local.az_map : {}
  route_table_id          = aws_route_table.private[each.key].id
  destination_cidr_block  = "0.0.0.0/0"
  nat_gateway_id          = aws_nat_gateway.main[each.key].id
}

# ======================================================================================
# PRIVATE ROUTE TABLE ASSOCIATIONS
# ======================================================================================
resource "aws_route_table_association" "private" {
  for_each          = local.az_map

  subnet_id         = aws_subnet.private[each.key].id
  route_table_id    =  aws_route_table.private[each.key].id
}


# =====================================================================================
# DATABASE ROUTE TABLES
# =====================================================================================
# Database subnets follow the same routing pattern as private subnets
# They get internet access via NAT gateway if enabled
# =====================================================================================
resource "aws_route_table" "database" {
  for_each  = local.az_map

  vpc_id    = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-database-rt-${each.key}"
    Environment = var.environment
    Component   = "networking"
    Tier        = "database"
  })
}

resource "aws_route_table_association" "database" {
  for_each          = local.az_map
  subnet_id         = aws_subnet.database[each.key].id
  route_table_id    = aws_route_table.database[each.key].id
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

  bucket        = "${var.project_name}-${var.environment}-vpc-flow-logs"
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


resource "aws_s3_bucket_server_side_encryption_configuration" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  bucket = aws_s3_bucket.flow_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
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
# TRUST POLICY
# ============================================================================================
data "aws_iam_policy_document" "flow_logs_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "flow_logs" {
  name                = "${var.project_name}-${var.environment}-vpc-flow-logs-role"
  assume_role_policy  = data.aws_iam_policy_document.flow_logs_assume_role.json
}


data "aws_iam_policy_document" "flow_logs_policy" {
  statement {
    effect = "Allow"

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.flow_logs[0].arn}/*"
    ]
  }
}

# Attach policy
resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name = "flow-logs-policy"
  role = aws_iam_role.flow_logs.id
  policy = data.aws_iam_policy_document.flow_logs_policy.json
}


data "aws_iam_policy_document" "flow_logs_bucket_policy" {
  statement {
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["s3:PutObject"]

    resources = [
      "${aws_s3_bucket.flow_logs[0].arn}/*"
    ]

    condition {
      test = "StringEquals"
      variable = "aws:SourceAccount"
      values = [data.aws_caller_identity.current.account_id]
    }
  }
}


resource "aws_s3_bucket_policy" "flow-logs" {
  count = var.enable_flow_logs ? 1 : 0

  bucket = aws_s3_bucket.flow_logs[0].id
  policy = data.aws_iam_policy_document.flow_logs_bucket_policy.json
}


# # VPC Flow Log
# resource "aws_flow_log" "vpc_flow_log" {
#   count = var.enable_flow_logs ? 1 : 0

#   log_destination       = aws_s3_bucket.flow_logs[0].arn
#   log_destination_type  = "s3"

#   traffic_type          = "ALL"
#   vpc_id                = aws_vpc.main.id
#   iam_role_arn          = aws_iam_role.flow_logs[0].arn
#   log_format            = "$${version} $${account-id} $${interface-id} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${protocol} $${packets} $${bytes} $${start} $${end} $${action} $${log-status}"

#   tags = merge(var.common_tags, {
#cod     Name = "${var.project_name}-$(var.environment)-flow-logs"
#   })
# }

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