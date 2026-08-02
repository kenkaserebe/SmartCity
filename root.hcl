# SmartCity/terragrunt.hcl

# Root configuration - shared across all environments
# Each environment defines its own

# Global inputs that all environments inherit
inputs = {
    project_name    = "smartcity"
    region          = "eu-west-2"
    aws_profile     = "default"

    # Network
    vpc_cidr                    = "10.0.0.0/16"
    public_subnet_cidrs         = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    private_subnet_cidrs        = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
    database_subnet_cidrs       = ["10.0.7.0/24", "10.0.8.0/24", "10.0.9.0/24"]
    availability_zones          = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
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
        key             = "smartcity/${var.environment}/terraform.tfstate"
        region          = "eu-west-2"
        encrypt         = true 
        use_lockfile    = true
    }
}