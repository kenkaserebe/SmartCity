# SmartCity/modules/security-groups/main.tf

# =============================================================================
# Security Groups Module - SmartCity IoT Platform
# =============================================================================
# Creates security groups for all components with proper ingress/egress rules
# =============================================================================

# =============================================================================
# DATA SOURCES
# =============================================================================

data "aws_vpc" "selected" {
  id = var.vpc_id
}

data "aws_subnet" "selected" {
  for_each  = toset(var.private_subnet_ids)
  id        = each.value
}

# =============================================================================
# 1. BASTION SECURITY GROUP
# =============================================================================
# For SSH access to EC2 instances in private subnets
# =============================================================================
resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-${var.environment}-bastion-sg"
  description = "Bastion host security group for SSH access"
  vpc_id      = var.vpc_id

  # Ingress: SSH from trusted IPs only
  dynamic "ingress" {
    for_each = var.bastion_allowed_cidrs
    content {
      description = "SSH from ${ingress.value}"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  # Egress: Allow all outbound traffic (bastion needs to connect to other resources)
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-bastion-sg"
    Environment = var.environment
    Component   = "bastion"
  })
}


# ========================================================================================
# 2. LOAD BALANCER SECURITY GROUP
# ========================================================================================
# For internet-facing load balancers (ALB/NLB)
# ========================================================================================
resource "aws_security_group" "load_balancer" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Load balancer security group for HTTP/HTTPS traffic"
  vpc_id      = var.vpc_id

  # Ingress: HTTP from internet
  ingress {
    description       = "HTTP from internet"
    from_port         = 80
    to_port           = 80
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
    ipv6_cidr_blocks  = ["::/0"]
  }

  # Ingress: HTTPS from internet
  ingress {
    description       = "HTTPS from internet"
    from_port         = 443
    to_port           = 443
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
    ipv6_cidr_blocks  = ["::/0"]
  }

  # Ingress: Health checks from ALB
  ingress {
    description = "Health check from load balancer"
    from_port   = var.load_balancer_health_check_port
    to_port     = var.load_balancer_health_check_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress: Allow all outbound (load balancer needs to talk to targets)
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-alb-sg"
    Environment = var.environment
    Component   = "load-balancer"
  })
}

# ================================================================================
# 3. APPLICATION SECURITY GROUP
# ================================================================================
# For application pods/EC2 instances running the services
# ================================================================================
resource "aws_security_group" "application" {
  name        = "${var.project_name}-${var.environment}-app-sg"
  description = "Application ssecurity group for service traffic"
  vpc_id      = var.vpc_id

  # Ingress: Traffic from load balancer
  ingress {
    description     = "Traffic from load balancer"
    from_port       = var.application_port
    to_port         = var.application_port
    protocol        = "tcp"
    security_groups = [aws_security_group.load_balancer.id]
  }

  # Ingress: Additional ports from load balancer (e.g. metrics, health)
  dynamic "ingress" {
    for_each = var.application_additional_ports
    content {
      description     = "Additional traffic from load balancer on port ${ingress.value}"
      from_port       = ingress.value
      to_port         = ingress.value
      protocol        = "tcp"
      security_groups = [aws_security_group.load_balancer.id]
    }
  }

  # Ingress: Allow traffic from other application services (internal microservices)
  ingress {
    description = "Internal application traffic from within the VPC"
    from_port   = var.application_port
    to_port     = var.application_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Ingress: Allow SSH from bastion (if needed)
  dynamic "ingress" {
    for_each = var.enable_bastion_ssh ? [1] : []
    content {
      description     = "SSH from bastion hosts"
      from_port       = 22
      to_port         = 22
      protocol        = "tcp"
      security_groups = [aws_security_group.bastion.id]
    }
  }

  # Egress: Application needs internet access (for dependencies, package management, etc.)
  egress {
    description = "Allow outbound traffic to internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-app-sg"
    Environment = var.environment
    Component   = "application"
  })
}


# ===================================================================================
# 4. DATABASE SECURITY GROUP
# ===================================================================================
# For RDS/Aurora databases - only allow traffic from application
# ===================================================================================
resource "aws_security_group" "database" {
  name        = "${var.project_name}-${var.environment}-db-sg"
  description = "Database security group for RDS/Aurora"
  vpc_id      = var.vpc_id

  # Ingress: Database port from application SG
  ingress {
    description     = "Database traffic from application"
    from_port       = var.database_port
    to_port         = var.database_port
    protocol        = "tcp"
    security_groups = [aws_security_group.application.id]
  }

  # Ingress: Database port from bastion for admin access
  dynamic "ingress" {
    for_each = var.enable_database_admin_access ? [1] : []
    content {
      description     = "Database admin access from bastion"
      from_port       = var.database_port
      to_port         = var.database_port
      protocol        = "tcp"
      security_groups = [aws_security_group.bastion.id]
    }
  }

  # Ingress: Allow database replication across subnets
  ingress {
    description = "Database replication within VPC"
    from_port   = var.database_port
    to_port     = var.database_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Egress: Database needs minimal outbound (usually just to internet for updates)
  egress {
    description = "Allow outbound to internet (for updates, monitoring)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-db-sg"
    Environment = var.environment
    Component   = "database"
  })
}


# ===================================================================================
# 5. REDIS/CACHE SECURITY GROUP
# ===================================================================================
# For Elasticache/Redis - only allow traffic from application
# ===================================================================================
resource "aws_security_group" "cache" {
  count       = var.enable_cache ? 1 : 0

  name        = "${var.project_name}-${var.environment}-cache-sg"
  description = "Cache/Redis security group"
  vpc_id      = var.vpc_id

  # Ingress: Cache port from application
  ingress {
    description     = "Cache traffic from application"
    from_port       = var.cache_port
    to_port         = var.cache_port
    protocol        = "tcp"
    security_groups = [aws_security_group.application.id]
  }

  # Ingress: Cache port from bastion for admin
  dynamic "ingress" {
    for_each = var.enable_database_admin_access ? [1] : []
    content {
      description     = "Cache admin access from bastion"
      from_port       = var.cache_port
      to_port         = var.cache_port
      protocol        = "tcp"
      security_groups = [aws_security_group.bastion.id]
    }
  }

  # Egress: Cache needs minimal outbound
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-cache-sg"
    Environment = var.environment
    Component   = "cache"
  })
}


# ===============================================================================
# 6. EKS CLUSTER SECURITY GROUP
# ===============================================================================
# For Kubernetes control plane communication
# ===============================================================================
resource "aws_security_group" "eks_cluster" {
  name        = "${var.project_name}-${var.environment}-eks-cluster-sg"
  description = "EKS cluster security group"
  vpc_id      = var.vpc_id

  # Ingress: HTTPS from nodes and other cluster resources
  ingress {
    description     = "Kubernetes API from nodes"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_node.id]
  }

  # Ingress: HTTPS from bastion for kubectl access
  dynamic "ingress" {
    for_each = var.enable_bastion_ssh ? [1] : []
    content {
      description     = "kubectl access from bastion"
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      security_groups = [aws_security_group.bastion.id]
    }
  }

  # Ingress: Webhook traffic (for admission controllers)
  ingress {
    description     = "Webhook traffic from application"
    from_port       = 9443
    to_port         = 9443
    protocol        = "tcp"
    security_groups = [aws_security_group.application.id]
  }

  # Egress: Allow all outbound
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-eks-cluster-sg"
    Environment = var.environment
    Component   = "kubernetes"
    Service     = "control-plane"
  })
}


# ==============================================================================
# 7. EKS NODE SECURITY GROUP
# ==============================================================================
# For worker nodes in the EKS cluster
# ==============================================================================
