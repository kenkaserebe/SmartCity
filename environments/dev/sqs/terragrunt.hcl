# SmartCity/environments/dev/sqs/terragrunt.hcl
# ==========================================================

include "root" {
    path = find_in_parent_folders("root.hcl")
}

terraform {
    source = "../../../modules/sqs"
}

# Dependencies
dependency "iam" {
    config_path = "../iam"

    mock_outputs = {
        eks_node_role_arn = "arn:aws:iam::000000000000:role/smartcity-dev-eks-node-role"
    }
}

remote_state = {
    backend = "s3"
    config = {
        bucket          = "smart-city-tfstate-${get_env("AWS_ACCOUNT_ID", "000000000000")}"
        key             = "smartcity/dev/sqs/terraform.tfstate"
        region          = "eu-west-2"
        encrypt         = true
        use_lockfile    = true
    }
}

inputs = {
    environment     = "dev"
    project_name    = "smartcity"

    # Queue Configuration
    fifo_queue                  = false
    delay_seconds               = 0
    max_message_size            = 262144
    message_retention_seconds   = 345600 # 4 days
    receive_wait_time_seconds   = 10
    visibility_timeout_seconds  = 30

    # Dead-Letter Queue
    enable_dlq = true
    dlq_message_retention_seconds   = 1209600 # 14 days
    max_receive_count               = 3

    # Encryption
    kms_master_key_id                   = "alias/aws/sqs"  # Use AWS managed KMS key
    kms_data_key_reuse_period_seconds   = 300

    # Sensor Queue (Disabled for dev)
    enable_sensor_queue         = false

    # Queue Policy
    enable_queue_policy         = true
    allowed_principals          = [ dependency.iam.outputs.eks_node_role_arn ]

    # S3 Notifications (Disabled for dev)
    enable_s3_notifications     = false

    # IAM Policy
    create_iam_policy           = true

    # CloudWatch Alarms (Disabled for dev)
    enable_cloudwatch_alarms    = false
    queue_depth_threshold       = 100
    dlq_depth_threshold         = 10
    alarm_actions               = []

    # Common Tags
    common_tags = {
        Environment = "dev"
        CostCenter  = "development"
        Project     = "SmartCity"
        ManagedBy   = "Terragrunt"
    }
}