# SmartCity/environments/dev/security-groups/terragrunt.hcl
# ==========================================================

include "root" {
    path = find_in_parent_folders("root.hcl")
}

terraform {
    source = "../../../modules/security-groups"
}

# Dependency on VPC module to get vpc_id and subnet IDs
dependency "vpc" {
    config_path = "../vpc"
}

inputs = {
    # From VPC
    vpc_id      = dependency.vpc.outputs.vpc_id
    vpc_cidr    = dependency.vpc.outputs.vpc_cidr

    # Environment
    environment = "dev"

    # Bastion - allow my machine's IP only
    bastion_allowed_cidrs   = ["1.2.3.4/32"] # Replace with personal IP
    enable_bastion_ssh      = true

    # Load balancer
    load_balancer_health_check_port = 80

    # Application
    application_port                = 8080
    application_additional_ports    = [8081, 8443] # Metrics, admin

    # Database
    database_port                   = 5432 # PostgreSQL
    enable_database_admin_access    = true

    # Cache
    eable_cache = true
    cache_port  = 6379   # Redis

    # Monitoring
    enable_monitoring   = true
    grafana_port        = 3000
    prometheus_port     = 9090

    # Common tags
    common_tags = {
        Environment = "dev"
        CostCenter  = "development"
    }
}