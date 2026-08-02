# SmartCity/environment/prod/terragrunt.hcl
# Production environment - production-grade settings
# =============================================================================

include "root" {
    path = find_in_parent_folders("root.hcl")
}

terraform {
    source = "../../modules/vpc/"
    # For production, you'd likely use a Git URL:
    # source = "git@github.com:your-org/terraform-modules.git//modules/vpc?ref=v1.0.0"
}

# prod-specific overrides
inputs = {
    environment                 = "prod"

    # Compute
    instance_type               = "t3.large"

    # Scaling
    min_size                    = 3
    max_size                    = 10
    desired_size                = 3

    # Features
    enable_nat_gateway          = true
    enable_flow_logs            = true
    enable_deletion_protection  = false     # Remember to change to true when necessary. This is false because its a test

    # Flow logs retention - 30 days for compliance
    flow_logs_retention_days    = 30

    # Common tags merged with environment
    common_tags = {
        Environment = "prod"
        CostCenter  = "production"
        Compliance  = "hipaa"
        PagerDuty   = "critical"
    }
}