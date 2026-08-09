# Smartcity/environment/dev/iam/terragrunt.hcl
# ============================================================

include "root" {
    path = find_in_parent_folders("root.hcl")
}

terraform {
    source = "../../../modules/iam"
}




inputs = {
    environment                 = "dev"

    # IRSA Configuration - OIDC will be created after EKS cluster exists
    create_oidc_provider = false
    namespace = "default"

    # Service access flags - enable what you need
    enable_s3_access = true
    enable_sqs-access = true
    enable_rds_access = true    # Enable if using IAM auth for RDS
    enable_ssm_access = true    # Enable for node management

    # Resource names (onlu used if corresponding access is enabled)
    s3_bucket_name = "smartcity-dev-data-bucket"
    sqs_queue_name = "smartcity-dev-queue"
    sqs_dlq_name = "smartcity-dev-dlq"
    rds_rdsource_id = ""    # Set when RDS is created
    rds_username = ""   # Set when RDS is created

    # Common tags
    common_tags = {
        Environment = "dev"
        CostCenter = "development"
    }
}