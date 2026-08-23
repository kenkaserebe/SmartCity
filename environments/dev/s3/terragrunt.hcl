# Smartcity/environment/dev/s3/terragrunt.hcl
# ============================================================

include "root" {
    path = find_in_parent_folders("root.hcl")
}

terraform {
    source = "../../../modules/s3"
}

remote_state {
    backend = "s3"
    config  = {
        bucket          = "smart-city-tfstate-${get_env("AWS_ACCOUNT_ID", "000000000000")}"
        key             = "smartcity/dev/s3/terraform.tfstate"
        region          = "eu-west-2"
        encrypt         = true
        use_lockfile    = true
    }
}

inputs = {
    environment     = "dev"
    project_name    = "smartcity"

    # Bucket Configuration
    force_destroy       = true    # Allow deletion in dev
    enable_versioning   = true
    create_iam_policy   = true

    # Static Assets (Optional - disabled for dev)
    enable_static_assets = false

    # Common Tags
    common_tags = {
        Environment = "dev"
        CostCenter  = "development"
        Project     = "SmartCity"
        ManagedBy   = "Terragrunt"
    }
}