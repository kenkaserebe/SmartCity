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

    subnets = {
        "eu-west-2a" = {
            public_cidr = "10.0.1.0/24"
            private_cidr = "10.0.4.0/24"
            database_cidr = "10.0.7.0/24"
        }

        "eu-west-2b" = {
            public_cidr = "10.0.2.0/24"
            private_cidr = "10.0.5.0/24"
            database_cidr = "10.0.8.0/24"
        }

        "eu-west-2c" = {
            public_cidr = "10.0.3.0/24"
            private_cidr = "10.0.6.0/24"
            database_cidr = "10.0.9.0/24"
        }
    }
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
        bucket          = "smart-city-tfstate-august"
        key             = "smartcity/${path_relative_to_include()}/terraform.tfstate"
        region          = "eu-west-2"
        encrypt         = true 
        use_lockfile    = true
    }
}