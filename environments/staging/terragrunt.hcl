# SmartCity/environment/staging/terragrunt.hcl

include "root" {
    path = find_in_parent_folders("terragrunt.hcl")
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
    environment                 = "staging"
    vpc_cidr                    = "10.0.0.0/16"
    instance_type               = "t3.medium"
    min_size                    = 2
    max_size                    = 5
    enable_deletion_protection  = false  # Set true if necessary
}