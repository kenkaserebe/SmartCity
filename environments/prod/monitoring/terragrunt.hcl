# SmartCity/environments/prod/monitoring/terragrunt.hcl

include {
    path = find_in_parent_folders()
}

terraform {
    source = "../../../modules/monitoring"
}

# Dependencies
dependency "eks" {
    config_path = "../eks"
    
    mock_outputs = {
        cluster_name = "smartcity-prod-eks-cluster"
        cluster_arn  = "arn:aws:eks:eu-west-2:000000000000:cluster/smartcity-prod-eks-cluster"
    }
}

dependency "iam" {
    config_path = "../iam"
    
    mock_outputs = {
        oidc_provider_arn = "arn:aws:iam::000000000000:oidc-provider/oidc.eks.eu-west-2.amazonaws.com/id/000000000000000000000000"
    }
}

dependency "rds" {
    config_path = "../rds"
    
    mock_outputs = {
        db_instance_id = "smartcity-prod-postgres"
        db_endpoint    = "smartcity-prod-postgres.xxxxxxxxxxxx.eu-west-2.rds.amazonaws.com"
    }
}

dependency "sqs" {
    config_path = "../sqs"
    
    mock_outputs = {
        main_queue_name = "smartcity-prod-queue"
        main_queue_url  = "https://sqs.eu-west-2.amazonaws.com/000000000000/smartcity-prod-queue"
    }
}

dependency "s3" {
    config_path = "../s3"
    
    mock_outputs = {
        sensor_data_bucket_id = "smartcity-prod-sensor-data"
    }
}

remote_state {
    backend = "s3"
    config = {
        bucket          = "smart-city-tfstate-${get_env("AWS_ACCOUNT_ID", "000000000000")}"
        key             = "smartcity/prod/monitoring/terraform.tfstate"
        region          = "eu-west-2"
        encrypt         = true 
        use_lockfile    = true
    }
}

inputs = {
    environment = "prod"
    region      = "eu-west-2"
    project_name = "smartcity"
    
    # EKS Configuration
    eks_cluster_name = dependency.eks.outputs.cluster_name
    eks_min_nodes    = 3
    
    # RDS Configuration
    rds_instance_id = dependency.rds.outputs.db_instance_id
    rds_cpu_threshold = 70
    
    # SQS Configuration
    sqs_queue_name = dependency.sqs.outputs.main_queue_name
    sqs_queue_url  = dependency.sqs.outputs.main_queue_url
    sqs_depth_threshold = 500
    
    # OIDC Configuration
    oidc_provider_arn = dependency.iam.outputs.oidc_provider_arn
    
    # Prometheus & Grafana
    enable_prometheus = true
    enable_grafana    = true
    prometheus_s3_bucket = dependency.s3.outputs.sensor_data_bucket_id
    
    # CloudWatch
    cloudwatch_log_retention = 90
    enable_cloudwatch_alarms = true
    
    # Alerts
    enable_sns_alerts = true
    alert_email       = "alerts@smartcity.example.com"
    alert_slack_webhook = "https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX"
    alarm_actions     = ["arn:aws:sns:eu-west-2:000000000000:smartcity-prod-alerts"]
    
    # Common Tags
    common_tags = {
        Environment = "prod"
        CostCenter  = "production"
        Project     = "SmartCity"
        ManagedBy   = "Terragrunt"
        Compliance  = "hipaa"
        PagerDuty   = "critical"
    }
}