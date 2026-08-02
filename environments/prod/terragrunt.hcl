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

remote_state {
    backend = "s3"
    config = {
        bucket          = "smart-city-tfstate-${get_env("AWS_ACCOUNT_ID")}"
        key             = "smartcity/prod/terraform.tfstate"
        region          = "eu-west-2"
        encrypt         = true 
        use_lockfile    = true
    }
}

# prod-specific overrides
inputs = {
    environment                 = "prod"

    # Network
    vpc_cidr                    = "10.0.0.0/16"
    public_subnet_cidrs         = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    private_subnet_cidrs        = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
    database_subnet_cidrs       = ["10.0.7.0/24", "10.0.8.0/24", "10.0.9.0/24"]
    availability_zones          = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]

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