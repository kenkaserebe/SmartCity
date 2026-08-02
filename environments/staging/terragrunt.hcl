# SmartCity/environment/staging/terragrunt.hcl
# Staging environment
# =============================================================================


include "root" {
    path = find_in_parent_folders("root.hcl")
}

terraform {
    source = "../../modules/vpc/"
}

# staging-specific overrides
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

    # Common tags merged with environment
    common_tags = {
        Environment = "staging"
        CostCenter  = "staging"
    }
}