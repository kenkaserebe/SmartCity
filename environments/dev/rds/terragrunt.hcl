# Smartcity/environment/dev/rds/terragrunt.hcl
# ============================================================

include "root" {
    path = find_in_parent_folders("root.hcl")
}

terraform {
    source = "../../../modules/rds"
}

# Dependencies
dependency "vpc" {
    config_path = "../vpc"

    mock_outputs = {
        vpc_id = "vpc-00000000"
        database_subnet_ids = ["subnet-00000000", "subnet-00000001", "subnet-00000002"]
        private_subnet_ids = ["subnet-00000000", "subnet-00000001", "subnet-00000002"]
    }
}

dependency "security_groups" {
    config_path = "../security-groups"

    mock_outputs = {
        database_sg_id = "sg-00000000"
    }
}

inputs = {
    environment = "dev"
    project_name = "smartcity"

    # Network
    database_subnet_ids = dependency.vpc.outputs.database_subnet_ids
    security_group_ids = [dependency.security_groups.outputs.database_sg_id]
    publicly_accessible = false 

    # Database Configuration
    database_name = "smartcity"
    port = 5432
    postgres_version = "18.3"
    postgres_version_major = "18"

    # Credentials (Use AWS Secrets Manager for production)
    username = "smartcity_admin"
    password = "ChangeMe123!"    # CHANGE THIS! Use a secure password

    # Instance Configuration
    instance_class = "db.t3.medium"
    allocated_storage = 20
    max_allocated_storage = 100
    storage_type = "gp3"
    storage_encrypted = true

    # High Availability (Disable for dev to save costs)
    multi_az = true
    # availability_zone = "eu-west-2a"

    # Backups
    backup_retention_period = 7
    backup_window = "03:00-05:00"
    maintenance_window = "Mon:05:00-Mon:07:00"

    # Deletion Protection
    deletion_protection = false    # Enable for prod

    # Parameter Groups  # aws rds describe-db-parameters --db-parameter-group-name default.postgres18
    max_connections = "100"
    shared_buffers = "131072"
    effective_cache_size = "524288"
    work_mem = "4096"
    maintenance_work_mem = "65536"
    wal_buffers = "4096"
    random_page_cost = "1.1"
    log_statement = "ddl"
    log_min_duration_statement = "5000"

    # Monitoring (Disabled for dev to save costs)
    performance_insights_enabled = true
    performance_insights_retention_period = 7
    monitoring_interval = 15

    # Logging
    enabled_cloudwatch_logs_exports = ["postgresql"]

    # IAM Authentication
    iam_database_authetication_enabled = false

    # Read Replica (Disabled for dev)
    enable_read_replica = false

    # RDS Proxy (Disabled for dev)
    enable_rds_proxy = false

    # Common Tags
    common_tags = {
        Environment = "dev"
        CostCenter = "development"
        Project = "SmartCity"
        ManagedBy = "Terragrunt"
    }
}