# SmartCity/environment/dev/terragrunt.hcl

include "root" {
    path = find_in_parent_folders("terragrunt.hcl")
}

terraform {
    source = "../../modules/vpc"
    # For production, you'd likely use a Git URL:
    # source = "git@github.com:your-org/terraform-modules.git//modules/vpc?ref=v1.0.0"
}

remote_state {
    backend = "s3"
    config = {
        bucket          = "smart-city-tfstate-${get_env("AWS_ACCOUNT_ID")}"
        key             = "smartcity/dev/terraform.tfstate"
        region          = "eu-west-2"
        encrypt         = true 
        use_lockfile    = true
    }
}

# The Inputs Block passes variables to the Terraform module
# Dev-specific overrides
inputs = {
    environment     = "dev"
    vpc_cidr        = "10.0.0.0/16"
    instance_type   = "t3.medium"
    min_size        = 1
    max_size        = 3
}