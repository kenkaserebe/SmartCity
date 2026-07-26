# SmartCity/environment/prod/terragrunt.hcl

include "root" {
    path = find_in_parent_folders("terragrunt.hcl")
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
    vpc_cidr                    = "10.0.0.0/16"
    instance_type               = "t3.large"
    min_size                    = 3
    max_size                    = 10
    enable_deletion_protection  = false  # Set true if necessary
}