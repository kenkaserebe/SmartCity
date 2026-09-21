# ===========================================================================
# Application Deployment Module - SmartCity IoT Platform
# ===========================================================================
# Deploys:
# - Namespaces
# - ConfigMaps and Secrets
# - Deployments and Services
# - Ingress rules
# - SeriviceMonitors for Prometheus
# ===========================================================================

terraform {
  backend "s3" {}
}


# ===========================================================================
# 1. PROVIDER CONFIGURATION
# ===========================================================================

provider "kubernetes" {
    host                    = var.eks_cluster_endpoint
    cluster_ca_certificate  = base64decode(var.eks_cluster_ca)
    exec {
        api_version = "client.authentication.k8s.io/v1beta1"
        command     = "aws"
        args        = ["eks", "get-token", "--cluster-name", var.eks_cluster_name, "--region", var.region]
    }
}

provider "helm" {
    kubernetes = {
        host                    = var.eks_cluster_endpoint
        cluster_ca_certificate  = base64decode(var.eks_cluster_ca)
        exec = {
            api_version = "client.authentication.k8s.io/v1beta1"
            command     = "aws"
            args        = ["eks", "get-token", "--cluster-name", var.eks_cluster_name, "--region", var.region]
        }
    }
}


# ===========================================================================
# 2. NAMESPACES
# ===========================================================================

resource "kubernetes_namespace" "smartcity" {
    metadata {
        name    = "smartcity"
        labels  = {
            name        = "smartcity"
            environment = var.environment
            managed-by  = "terraform"
        }
    }
}

resource "kubernetes_namespace" "monitoring" {
    count = var.deploy_monitoring ? 1 : 0

    metadata {
        name    = "monitoring"
        labels  = {
            name        = "monitoring"
            environment = var.environment
            managed     = "terraform"
        }
    }
}

resource "kubernetes_namespace" "ingress" {
    count = var.deploy_ingress_controller ? 1 : 0

    metadata {
        name    = "ingress-nginx"
        labels  = {
            name        = "ingress-nginx"
            environment = var.environment
            managed-by  = "terraform"
        }
    }
}


# ===========================================================================
# 3. CONFIGMAPS
# ===========================================================================

# Application configuration
resource "kubernetes_config_map" "app_config" {
    metadata {
        name        = "smartcity-config"
        namespace   = kubernetes_namespace.smartcity.metadata[0].name
    }

    data = {
        # Database
        "DB_HOST"       = var.rds_endpoint
        "DB_PORT"       = var.rds_port
        "DB_NAME"       = var.rds_db_name
        "DB_USER"       = var.rds_username

        # SQS
        "SQS_QUEUE_URL" = var.sqs_queue_url
        "SQS_REGION"    = var.region

        # S3
        "S3_BUCKET"     = var.s3_bucket_name
        "S3_REGION"     = var.region

        # Application
        "APP_ENV"       = var.environment
        "LOG_LEVEL"     = var.log_level
        "API_PORT"      = var.api_port
        "METRICS_PORT"  = var.metrics_port
    }
}


# ===========================================================================
# 4. SECRETS (Using Kubernetes Secrets)
# ===========================================================================

resource "kubernetes_secret" "app_secrets" {
    metadata {
        name        = "smartcity-secrets"
        namespace   = kubernetes_namespace.smartcity.metadata[0].name
    }

    data = {
        # Database password (base64 encoded)
        DB_PASSWORD   = base64encode(var.rds_password)

        # API Keys 
        API_KEY       = base64encode(var.api_key)
    }

    type = "Opaque"
}


# ===========================================================================
# 5. API GATEWAY DEVELOPMENT
# ===========================================================================

resource "kubernetes_deployment" "api_gateway" {
    metadata {
        name        = "api-gateway"
        namespace   = kubernetes_namespace.smartcity.metadata[0].name
        labels      = {
            app     = "api-gateway"
            version = "v1"
        }
    }

    spec {
        replicas = var.api_replicas

        selector {
            match_labels = {
                app = "api-gateway"
            }
        }

        template {
            metadata {
                labels = {
                    app         = "api-gateway"
                    version     = "v1"
                }
                annotations = {
                    "prometheus.io/scrape"  = "true"
                    "prometheus.io/port"    = var.metrics_port
                    "prometheus.io/path"    = "/metrics"
                }
            }

            spec {
                container {
                    name                = "api-gateway"
                    image               = var.api_image
                    image_pull_policy   = "Always"

                    env_from { 
                        config_map_ref {
                            name = kubernetes_config_map.app_config.metadata[0].name
                        }
                    }

                    env_from {
                        secret_ref {
                            name = kubernetes_secret.app_secrets.metadata[0].name
                        }
                    }

                    port {
                        name            = "http"
                        container_port  = var.api_port
                    }

                    port {
                        name            = "metrics"
                        container_port  = var.metrics_port
                    }

                    resources {
                        limits = {
                            cpu     = var.api_cpu_limit
                            memory  = var.api_memory_limit
                        }
                        requests = {
                            cpu     = var.api_cpu_request
                            memory  = var.api_memory_request
                        }
                    }

                    liveness_probe {
                        http_get {
                            path = "/health"
                            port = var.api_port
                        }
                        initial_delay_seconds   = 39
                        period_seconds          = 10
                    }

                    readiness_probe {
                        http_get {
                            path = "/ready"
                            port = var.api_port
                        }
                        initial_delay_seconds   = 10
                        period_seconds          = 5
                    }
                }
            }
        }
    }

    depends_on = [
        kubernetes_namespace.smartcity
    ]
}


# ===========================================================================
# 6. API GATEWAY SERVICE
# ===========================================================================

resource "kubernetes_service" "api_gateway" {
    metadata {
        name        = "api-gateway-service"
        namespace   = kubernetes_namespace.smartcity.metadata[0].name
        labels      = {
            app = "api-gateway"
        }
        annotations = {
            # Enable AWS Load Balancer Controller
            "service.beta.kubernetes.io/aws-load-balancer-type"     = "nlb"
            "service.beta.kubernetes.io/aws-load-balancer-scheme"   = "internal"
        }
    }

    spec {
        type = "ClusterIP"

        port {
            name        = "http"
            port        = 80
            target_port = var.api_port
            protocol    = "TCP"
        }

        selector = { 
            app = "api-gateway"
        }
    }
}


# ===========================================================================
# 7. WORKER SERVICE DEPLOYMENT (Sensor Data Processing)
# ===========================================================================

resource "kubernetes_deployment" "worker" {
    metadata {
        name        = "sensor-worker"
        namespace   = kubernetes_namespace.smartcity.metadata[0].name
        labels      = {
            app     = "sensor-worker"
            version = "v1"
        }
    }

    spec {
        replicas = var.worker_replicas

        selector { 
            match_labels = {
                app = "sensor-worker"
            }
        }
        
        template {
            metadata {
                labels = {
                    app = "sensor-worker"
                    version = "v1"
                }
                annotations = {
                    "prometheus.io/scrape"  = "true"
                    "prometheus.io/port"    = var.metrics_port
                    "prometheus.io/path"    = "/metrics"
                }
            }

            spec {
                container {
                    name                = "sensor-worker"
                    image               = var.worker_image
                    image_pull_policy   = "Always"

                    env_from {
                        config_map_ref {
                            name = kubernetes_config_map.app_config.metadata[0].name
                        }
                    }

                    env_from { 
                        secret_ref {
                            name = kubernetes_secret.app_secrets.metadata[0].name
                        }
                    }

                    port {
                        name            = "metrics"
                        container_port  = var.metrics_port
                    }

                    resources {
                        limits = {
                            cpu     = var.worker_cpu_limit
                            memory  = var.worker_memory_limit
                        }

                        requests = {
                            cpu     = var.worker_cpu_request
                            memory  = var.worker_memory_request
                        }
                    }

                    # Worker-specific environment
                    env {
                        name    = "WORKER_TYPE"
                        value   = var.worker_type
                    }

                    env {
                        name    = "WORKER_QUEUE"
                        value   = "sensor-data"
                    }
                }
            }
        }
    }

    depends_on = [
        kubernetes_namespace.smartcity,
        kubernetes_config_map.app_config
    ]
}


# ===========================================================================
# 8. INGRESS CONTROLLER (NGINX)
# ===========================================================================

resource "helm_release" "nginx_ingress" {
    count = var.deploy_ingress_controller ? 1 : 0

    name        = "ingress-nginx"
    repository  = "https://kubernetes.github.io/ingress-nginx"
    chart       = "ingress-nginx"
    version     = var.nginx_ingress_version
    namespace   = kubernetes_namespace.ingress[0].metadata[0].name

    values = [
        <<-EOF
controller:
    replicaCount: ${var.ingress_replicas}
    service:
        type: LoadBalancer
        annotations:
            service.beta.kubernetes.io/aws-load-balancer-type: nlb
            service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
    ingressClass: nginx
    watchIngressWithoutClass: true
    config:
        client-body-buffer-size: "64k"
        proxy-body-size: "10m"
        keep-alive-requests: "100"
        keep-alive: "60s"
EOF
    ]

    depends_on = [
        kubernetes_namespace.ingress
    ]
}


data "kubernetes_service_v1" "nginx_ingress" {
    count = var.deploy_ingress_controller ? 1 : 0

    metadata {
        name        = "ingress-nginx-controller"
        namespace   = kubernetes_namespace.ingress[0].metadata[0].name
    }

    depends_on = [
        helm_release.nginx_ingress
    ]
}


# ===========================================================================
# 9. INGRESS RULES
# ===========================================================================

resource "kubernetes_ingress_v1" "smartcity" {
    metadata {
        name        = "smartcity-ingress"
        namespace   = kubernetes_namespace.smartcity.metadata[0].name
        annotations = {
            "kubernetes.io/ingress.class"                   = "nginx"
            "nginx.ingress.kubernetes.io/rewrite-target"    = "/"
            "nginx.ingress.kubernetes.io/proxy-body-size"   = "10m"
            "nginx.ingress.kubernetes.io/ssl-redirect"      = var.enable_tls ? "true" : "false"
        }
    }

    spec {
        # Default backend
        default_backend {
            service {
                name = kubernetes_service.api_gateway.metadata[0].name
                port {
                    number = 80
                }
            }
        }

        # API routes
        rule {
            host = var.domain_name
            http {
                path { 
                    path        = "/api"
                    path_type   = "Prefix"
                    backend {
                        service {
                            name = kubernetes_service.api_gateway.metadata[0].name
                            port {
                                number = 80
                            }
                        }
                    }
                }

                path {
                    path        = "/health"
                    path_type   = "Prefix"
                    backend {
                        service {
                            name = kubernetes_service.api_gateway.metadata[0].name
                            port {
                                number = 80
                            }
                        }
                    }
                }
            }
        }

        # TLS configuration
        dynamic "tls" {
            for_each = var.enable_tls ? [1] : []
            content {
                hosts       = [var.domain_name]
                secret_name = kubernetes_secret.tls[0].metadata[0].name
            }
        }
    }

    depends_on = [
        kubernetes_service.api_gateway,
        kubernetes_ingress_class.nginx
    ]
}


# ===========================================================================
# 10. TLS SECRET
# ===========================================================================

resource "kubernetes_secret" "tls" {
    count = var.enable_tls ? 1 : 0

    metadata {
        name        = "tls-secret"
        namespace   = kubernetes_namespace.smartcity.metadata[0].name
    }

    data = {
        "tls.crt" = base64encode(var.tls_certificate)
        "tls.key" = base64encode(var.tls_private_key)
    }

    type = "kubernetes.io/tls"
}


# ===========================================================================
#  11. INGRESS CLASS
# ===========================================================================

resource "kubernetes_ingress_class" "nginx" {
    count = var.deploy_ingress_controller ? 1 : 0

    metadata {
        name        = "nginx"
        annotations = {
            "ingress.kubernetes.io/is-default-class" = "true"
        }
    }

    spec {
        controller = "k8s.io/ingress-nginx"
    }
}


# ===========================================================================
# 12. SERVICE MONITOR (Prometheus)
# ===========================================================================

resource "kubernetes_manifest" "service_monitor_api" {
    count = var.enable_service_monitor ? 1 : 0

    manifest = {
        apiVersion  = "monitoring.coreos.com/v1"
        kind        = "ServiceMonitor"

        metadata    = {
            name        = "smartcity-api"
            namespace   = kubernetes_namespace.smartcity.metadata[0].name

            labels      = {
                release = "prometheus"
            }
        }

        spec = {
            selector = {
                matchLabels = {
                    app = "api-gateway"
                }
            }

            endpoints = [
                {
                    port        = "metrics"
                    path        = "/metrics"
                    interval    = "30s"
                }
            ]

            namespaceSelector = {
                matchNames = [
                    kubernetes_namespace.smartcity.metadata[0].name
                ]
            }
        }
    }
}

resource "kubernetes_manifest" "service_monitor_worker" {
    count = var.enable_service_monitor ? 1 : 0

    manifest = {
        apiVersion  = "monitoring.coreos.com/v1"
        kind        = "ServiceMonitor"

        metadata = {
            name        = "smartcity-worker"
            namespace   = kubernetes_namespace.smartcity.metadata[0].name

            labels      = {
                release = "prometheus"
            }
        }
        
        spec = {
            selector = {
                matchLabels = {
                    app = "sensor-worker"
                }
            }

            endpoints = [
                {
                    port        = "metrics"
                    path        = "/metrics"
                    interval    = "30s"
                }
            ]

            namespaceSelector = {
                matchNames = [
                    kubernetes_namespace.smartcity.metadata[0].name
                ]
            }
        }
    }
}


# ===========================================================================
# 13. POD DISRUPTION BUDGET
# ===========================================================================

resource "kubernetes_pod_disruption_budget" "api" {
    metadata {
        name        = "api-gateway-pdb"
        namespace   = kubernetes_namespace.smartcity.metadata[0].name
    }

    spec {
        min_available = 1

        selector {
            match_labels = {
                app = "api-gateway"
            }
        }
    }
}

resource "kubernetes_pod_disruption_budget" "worker" {
    metadata {
        name        = "sensor-worker-pdb"
        namespace   = kubernetes_namespace.smartcity.metadata[0].name
    }

    spec {
        min_available = 1

        selector {
            match_labels = {
                app = "sensor-worker"
            }
        }
    }
}


# ===========================================================================
# 14. HORIZONTAL POD AUTOSCALER
# ===========================================================================

resource "kubernetes_horizontal_pod_autoscaler" "api" {
    metadata {
        name        = "api-gateway-hpa"
        namespace   = kubernetes_namespace.smartcity.metadata[0].name
    }

    spec {
        max_replicas                        = var.api_max_replicas
        min_replicas                        = var.api_replicas
        target_cpu_utilization_percentage   = 70

        scale_target_ref {
            api_version = "apps/v1"
            kind        = "Deployment"
            name        = kubernetes_deployment.api_gateway.metadata[0].name
        }
    }
}

resource "kubernetes_horizontal_pod_autoscaler" "worker" {
    metadata {
        name        = "sensor-worker-hpa"
        namespace   = kubernetes_namespace.smartcity.metadata[0].name
    }

    spec {
        max_replicas                        = var.worker_max_replicas
        min_replicas                        = var.worker_replicas
        target_cpu_utilization_percentage   = 70

        scale_target_ref {
            api_version = "apps/v1"
            kind        = "Deployment"
            name        = kubernetes_deployment.worker.metadata[0].name
        }
    }
}


# ===========================================================================
# 15. DATA SOURCES 
# ===========================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
