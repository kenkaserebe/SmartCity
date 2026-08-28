# Smartcity/environment/dev/monitoring/terragrunt.hcl
# ============================================================

include "root" {
    path = find_in_parent_folders("root.hcl")
}

terraform {
    source = "../../../modules/monitoring"
}

# Dependencies
dependency "eks" {
    config_path = "../eks"

    mock_outputs = {
        cluster_name = "smartcity-dev-eks-cluster"
        cluster_arn = "arn:aws:eks:eu-west-2:000000000000:cluster/smartcity-dev-eks-cluster"
    }
}

dependency "iam" {
    config_path = "../iam"

    mock_outputs = {
        oidc_provider_arn = "arn:aws:iam:000000000000:oidc-provider/oidc.eks.eu-west-2.amazonaws.com/id/000000000000"
    }
}

dependency "rds" {
    config_path = "../rds"

    mock_outputs = {
        db_instance_id = "smartcity-dev-postgres"
        db_endpoints = "smartcity-dev-postgres.xxxxxxxxxxxx.eu-west-2.rds.amazonaws.com"
    }
}

dependency "sqs" {
    config_path = "../sqs"

    mock_outputs = {
        main_queue_name = "smartcity-dev-queue"
        main_queue_url = "https://sqs.eu-west-2.amazonaws.com/000000000000/smartcity-dev-queue"
    }
}

remote_state {
    backend = "s3"
    config = {
        bucket = "smart-city-tfstate-${get_env("AWS_ACCOUNT_ID", "000000000000")}"
        key = "smartcity/dev/monitoring/terraform.tfstate"
        region = "eu-west-2"
        encrypt = true
        use_lockfile = true
    }
}

inputs = {
    environment = "dev"
    region = "eu-west-2"
    project_name = "smartcity"

    # EKS Configuration
    eks_cluster_name = dependency.eks.outputs.cluster_name
    eks_min_nodes = 1

    # RDS Configuration
    rds_instance_id = dependency.rds.outputs.db_instance_id
    rds_cpu_threshold = 80

    # SQS Configuration
    sqs_queue_name = dependency.sqs.outputs.main_queue_name
    sqs_queue_url = dependency.sqs.outputs.main_queue_url
    sqs_depth_threshold = 100

    # OIDC Configuration
    oidc_provider_arn = dependency.iam.outputs.oidc_provider_arn

    # Prometheus & Grafana
    enable_prometheus = true
    enable_grafana = true

    # CloudWatch
    cloudwatch_log_retention = 30
    enable_cloudwatch_alarms = true

    # Alerts
    enable_sns_alerts = false
    alert_email = ""
    alert_slack_webhook = ""
    alarm_actions = []

    # Common Tags
    common_tags = {
        Environment = "dev"
        CostCenter = "development"
        Project = "SmartCity"
        ManagedBy = "Terragrunt"
    }
}