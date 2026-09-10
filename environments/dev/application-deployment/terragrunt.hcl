# SmartCity/environment/dev/application-deployment/terragrunt.hcl

include "root" {
    path = find_in_parent_folders("root.hcl")
}

terraform {
    source = "../../../modules/application-deployment"
}

# Dependencies
dependency "eks" {
    config_path = "../eks"

    mock_outputs = {
        cluster_name                        = "smartcity-dev-eks-cluster"
        cluster_endpoint                    = "https://mock-cluster-endpoint.eks.amazonaws.com"
        cluster_certificate_authority_data  = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCVENDQWUyZ0F3SUJBZ0lJQk5YV1hTdG5VY3d3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TlRBeE1qUXdNakF4TURCYUZ3MHpOVEF4TWpRd01qQXhNREJhTUJVeApFekFSQmdOVkJBTVRDbXQxWW1WeWJtVjBaWE13Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCkFvSUJBUUN6VWlWckZ1akVWMmdmRkh0dFo1NlJmVkFDMmFMLzN4VnZqS1lzQVdIeDJZeEN6Z1hPWnF0VHBGM28KQ0JTKzlKcUZFRWg2Z1NHb0t1Z0JLOThrVlBBWmhMWnFmdXhXM1ZhbkZKRkVwam8xWktBQzR3d2p0ZWs1TGxsYQo5VjZtU1lOUng3a2h4b0RkUklwSWFucDZYUmZ3a0RBYldETGlnSlNGcTZVN1NBRUpqdzVoYndxbXA4QndFc1RDCitVTXZZYVdRZ0o2dTJNR2ZkSXdHbm9rbHg3VjlaV1dOU1p0R1pUODNoeXpjMldHZEU5Ujd3a3hFdXkzYmpSbUoKblhUZ0JzN3dSOFJReFlrRHRWOVhTemMvUlkvYlBIaGlQTktOS1oyV1hLODNoTDhZRHBUQSt0dkh3T3puVmJSNQpXTkFFK1N0QXl0b09CekhsU1N5QWdNQkFBR2pJekFoTUE0R0ExVWREd0VCL3dRRUF3SUNwREFQQmdOVkhSTUJBCjhGOENVUUV3RFFZSktvWklodmNOQVFFTEJRQURnZ0VCQUkwYkdFa3FXU1ZoSFpCcGxEdjNXVUtkaUxNZ05jNysKQ00yZS9JbmI1WWF1WTRPTUdnVFE4WWV5bHhGNk1zeFduRTFwbE1vckF1NENLeGd4N3JYenNuSDhCb0pIVldlNQpuUzIzWldUdjQzUkMvSnU3aHphK0UzcmNCR2twalVVV0U0RkMzc3E0YThzTG1GTTlFZ3FFcmE4WkdmcGJwY3pHCmoyOCtTb3RNM2VWeURPQ3d1YXNtZGR4YkM4YnlYYUppbU5FdGwwdlFRNTE2RXJsSXh5czIzaXk1NW9hMTNVUWcKUU9FczRFUzhzYml4NHNpYjdHRUliMUNiWHcwSUNEcHZmR05mR2pBN3BWczhZcWdSUzBGVVJkMVZJRS9ubjQxQwpLd09Ccm5ZTUJkM2dJVVlPdnFjS3UxZ3FONlpxbGd3eHpFQzhBbUhNUkRkVS9rdWFON3c9Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K"
    }
}

dependency "rds" {
    config_path = "../rds"

    mock_outputs = {
        db_instance_id  = "smartcity-dev-postgres"
        db_endpoint     = "smartcity-dev-postgres.xxxxxxxxxxxx.eu-west-2.rds.amazonaws.com"
        db_port         = "5432"
        db_name         = "smartcity"
        db_username     = "smartcity_admin"
    }
}

dependency "sqs" {
    config_path = "../sqs"

    mock_outputs = {
        main_queue_url = "https://sqs.eu-west-2.amazonaws.com/000000000000/smartcity-dev-queue"
    }
}

dependency "s3" {
    config_path = "../s3"

    mock_outputs = {
        sensor_data_bucket_id = "smartcity-dev-sensor-data"
    }
}

# =================================================================================================
# REMOTE STATE
# =================================================================================================

remote_state {
    backend = "s3"
    config = {
        bucket          = "smart-city-tfstate-${get_env("AWS_ACCOUNT_ID", "000000000000")}"
        key             = "smartcity/dev/application-deployment/terraform.tfstate"
        region          = "eu-west-2"
        encrypt         = true
        use_lockfile    = true
    }
}


# =================================================================================================
# INPUTS
# =================================================================================================

inputs = {
    environment = "dev"
    project_name = "smartcity"
    region          = "eu-west-2"

    # ==========================================================================
    # EKS cluster
    # ==========================================================================

    eks_cluster_name        = dependency.eks.outputs.cluster_name
    eks_cluster_endpoint    = dependency.eks.outputs.cluster_endpoint
    eks_cluster_ca          = dependency.eks.outputs.cluster_certificate_authority_data


    # ==========================================================================
    # Application Images
    # ==========================================================================

    api_image       = "smartcity/api-gateway:dev-latest"
    worker_image    = "smartcity/sensor-worker:dev-latest"


    # ==========================================================================
    # Application Ports 
    # ==========================================================================

    api_port        = 8080
    metrics_port    = 9090

    # ==========================================================================
    # Domain (Dev - local/testing)
    # ==========================================================================

    domain_name = "dev.smartcity.example.com"


    # ==========================================================================
    # Database Configuration
    # ==========================================================================
    rds_endpoint    = dependency.rds.outputs.db_endpoint
    rds_port        = dependency.rds.outputs.db_port
    rds_db_name     = "smartcity"
    rds_username    = dependency.rds.outputs.db_username
    rds_password    = "ChangeMe123!" # Use AWS Secrets Manager in production


    # ==========================================================================
    # SQS Configuration
    # ==========================================================================

    sqs_queue_url = dependency.sqs.outputs.main_queue_url


    # ==========================================================================
    # S3 Configuration
    # ==========================================================================

    s3_bucket_name = dependency.s3.outputs.sensor_data_bucket_id


    # ==========================================================================
    # API Key (For external integrations)
    # ==========================================================================

    api_key = "dev-api-key-12345"


    # ==========================================================================
    # Logging
    # ==========================================================================

    log_level = "DEBUG"


    # ==========================================================================
    # Scaling Configuration
    # ==========================================================================
    api_replicas        = 1
    api_max_replicas    = 3
    worker_replicas     = 1
    worker_max_replicas = 5


    # ==========================================================================
    # Resource Limits (Smaller for dev)
    # ==========================================================================

    api_cpu_request         = "50m"
    api_cpu_limit           = "250m"
    api_memory_request      = "128Mi"
    api_memory_limit        = "256Mi"

    worker_cpu_request      = "50m"
    worker_cpu_limit        = "500m"
    worker_memory_request   = "128Mi"
    worker_memory_limit     = "512Mi"


    # ==========================================================================
    # Worker Configuration
    # ==========================================================================

    worker_type = "sensor"


    # ==========================================================================
    # Ingress Configuration
    # ==========================================================================

    deploy_ingress_controller   = true
    nginx_ingress_version       = "4.9.0"
    ingress_replicas            = 1


    # ==========================================================================
    # TLS
    # ==========================================================================
    
    enable_tls      = true
    tls_certificate = ""
    tls_private_key = ""

    # ==========================================================================
    # Monitoring
    # ==========================================================================

    enable_service_monitors = true
    deploy_monitoring       = true


    # ==========================================================================
    # Common Tags
    # ==========================================================================

    common_tags = {
        Environment = "dev"
        CostCenter  = "development"
        Project     = "SmartCity"
        ManagedBy   = "Terragrunt"
        Application = "smartcity-platform"
    }
}