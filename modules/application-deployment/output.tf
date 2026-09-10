# ===========================================================================
# Application Deployment Module - Outputs
# ===========================================================================

# ===========================================================================
# NAMESPACE OUTPUTS
# ===========================================================================

output "namespace_name" {
    description = "Name of the SmartCity namespace"
    value       = kubernetes_namespace.smartcity.metadata[0].name
}


# ===========================================================================
# SERVICE OUTPUTS
# ===========================================================================

output "api_service_name" {
    description = "Name of the API Gateway service"
    value       = kubernetes_service.api_gateway.metadata[0].name
}


output "api_service_cluster_ip" {
    description = "Cluster IP of the API Gateway service"
    value       = kubernetes_service.api_gateway.spec[0].cluster_ip
}


# ===========================================================================
# INGRESS OUTPUTS
# ===========================================================================


output "ingress_host" {
    description = "Ingress hostname"
    value       = var.domain_name
}


output "nginx_ingress_load_balancer" {
    description = "NGINX Ingress Load Balancer hostname"
    value       = var.deploy_ingress_controller ? try(data.kubernetes_service_v1.nginx_ingress[0].status[0].load_balancer[0].ingress[0].hostname, null) : null
}


# ===========================================================================
# DEPLOYMENT OUTPUTS
# ===========================================================================

output "api_deployment_replicas" {
    description = "Desired number of API Gateway replicas"
    value       = var.api_replicas
}

output "worker_deployment_replicas" {
    description = "Desired number of Sensor Worker replicas"
    value       = var.worker_replicas
}


# ===========================================================================
# SUMMARY
# ===========================================================================


output "application_summary" {
    description = "Summary of application resources"
    value       = {
        namespace       = kubernetes_namespace.smartcity.metadata[0].name
        api_service     = kubernetes_service.api_gateway.metadata[0].name
        api_replicas    = var.api_replicas
        worker_replicas = var.worker_replicas
        ingress_host    = var.domain_name
        nginx_ingress   = var.deploy_ingress_controller ? try(data.kubernetes_service_v1.nginx_ingress[0].status[0].load_balancer[0].ingress[0].hostname, null) : null
    }
}