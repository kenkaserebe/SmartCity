# SmartCity/terragrunt.hcl

# Root configuration - shared across all environments
# Each environment defines its own

# Global inputs that all environments inherit
inputs = {
    project_name    = "smartcity"
    region          = "eu-west-2"
    aws_profile     = "default"
}

# Common tags applied to all resources
locals {
    common_tags = {
        Project     = "SmartCity"
        ManagedBy    = "Terragrunt"
    }
}

remote_state {
    backend = "s3"
    config = {
        bucket          = "smart-city-tfstate-july"
        key             = "smartcity/dev/terraform.tfstate"
        region          = "eu-west-2"
        encrypt         = true 
        use_lockfile    = true
    }
}