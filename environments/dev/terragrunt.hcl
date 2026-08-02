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