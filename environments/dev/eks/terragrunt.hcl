# Smartcity/environment/dev/eks/terragrunt.hcl
# ============================================================

include "root" {
    path = find_in_parent_folders("root.hcl")
}

terraform {
    source = "../../../modules/eks"
}

# Dependencies
dependency "vpc" {
    config_path = "../vpc"

    mock_outputs = {
        vpc_id = "vpc-00000000"
        vpc_cidr = "10.0.0.0/16"
        private_subnet_ids = ["subnet-00000000", "subnet-00000001", "subnet-00000002"]
        public_subnet_ids = ["subnet-00000000", "subnet-00000001", "subnet-00000002"]
        database_subnet_ids = ["subnet-00000000", "subnet-00000001", "subnet-00000002"]
    }
}

dependency "security_groups" {
    config_path = "../security-groups"

    mock_outputs = {
        eks_cluster_sg_id = "sg-00000000"
        eks_node_sg_id = "sg-00000000"
    }
}

dependency "iam" {
    config_path = "../iam"

    mock_outputs = {
        eks_cluster_role_arn = "arn:aws:iam::000000000000:role/smartcity-dev-eks-cluster-role"
        eks_node_role_arn = "arn:aws:iam::000000000000:role/smartcity-dev-eks-node-role"
        oidc_provider_arn = null
    }
}

inputs = {
    environment = "dev"
    project_name = "smartcity"

    # VPC Configuration
    private_subnet_ids = dependency.vpc.outputs.private_subnet_ids

    # IAM Roles
    cluster_role_arn = dependency.iam.outputs.eks_cluster_role_arn
    node_role_arn = dependency.iam.outputs.eks_node_role_arn

    # Security Groups
    cluster_security_group_ids = [
        dependency.security_groups.outputs.eks_cluster_sg_id,
        dependency.security_groups.outputs.eks_node_sg_id
    ]

    # Kubernetes Version
    kubernetes_version = "1.36"

    # Endpoint Configuration
    endpoint_private_access = true
    endpoint_publice_access = false     # Private only for dev

    # Node Group Configuration
    node_instance_types = ["t3.medium"]
    node_capacity_type = "ON_DEMAND"
    node_desired_size = 2
    node_min_size = 1
    node_max_size = 4
    node_max_unavailable = 1

    # SSH Access (disabled for dev)
    node_ssh_key_name = ""
    node_ssh_security_group_ids = []

    # Specialized Node Group (disabled for dev)
    enable_specialized_node_group = false

    # OIDC Provider
    create_oidc_provider = true

    # Add-ons
    vpc_cni_version = "v1.23.0-eksbuild.1"
    coredns_version = "v1.14.3-eksbuild.3"
    kube_proxy_version = "v1.36.0-eksbuild.14"
    enable_lb_controller = false    # Enable if using ALB/NLB

    # Common tags
    common_tags = {
        Environment = "dev"
        CostCenter = "development"
    }
}