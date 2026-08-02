# SmartCity/environment/staging/terragrunt.hcl
# Staging environment
# =============================================================================


include "root" {
    path = find_in_parent_folders("root.hcl")
}

terraform {
    source = "../../modules/vpc/"
}

remote_state {
    backend = "s3"
    config = {
        bucket          = "smart-city-tfstate-${get_env("AWS_ACCOUNT_ID")}"
        key             = "smartcity/staging/terraform.tfstate"
        region          = "eu-west-2"
        encrypt         = true 
        use_lockfile    = true
    }
}

# staging-specific overrides
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

    # Common tags merged with environment
    common_tags = {
        Environment = "staging"
        CostCenter  = "staging"
    }
}