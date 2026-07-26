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
        ManageBy    = "Terragrunt"
        Environment = get_env("ENVIRONMENT", "dev")
    }
}
