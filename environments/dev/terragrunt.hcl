# SmartCity/environment/dev/terragrunt.hcl
# Development environment
# =============================================================================

include "root" {
    path = find_in_parent_folders("root.hcl")
}

terraform {
    source = "../../modules/vpc/"
}



# The Inputs Block passes variables to the Terraform module
# Dev-specific overrides
inputs = {
    environment                 = "dev"

    # Network
    vpc_cidr                    = "10.0.0.0/16"
    public_subnet_cidrs         = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    private_subnet_cidrs        = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
    database_subnet_cidrs       = ["10.0.7.0/24", "10.0.8.0/24", "10.0.9.0/24"]
    availability_zones          = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]

    # Compute
    instance_type               = "t3.medium"

    # Scaling
    min_size                    = 1
    max_size                    = 3
    desired_size                = 1

    # Features
    enable_nat_gateway          = true
    enable_flow_logs            = true
    enable_deletion_protection  = false
    flow_logs_retention_days    = 7

    # Common tags merged with environment
    common_tags = {
        Environment = "dev"
        CostCenter  = "development"
    }
}