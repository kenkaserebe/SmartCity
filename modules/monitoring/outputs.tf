# =============================================================================
# Monitoring Module - Outputs
# =============================================================================

# =============================================================================
# CLOUDWATCH OUTPUTS
# =============================================================================

output "aws_cloudwatch_log_groups" {
  description = "List of CloudWatch log group names"
  value = {
    eks_cluster = aws_cloudwatch_log_group.eks_cluster.name
    rds = aws_cloudwatch_log_group.rds.name
    application = aws_cloudwatch_log_group.application.name
  }
}

output "aws_cloudwatch_dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value = aws_cloudwatch_dashboard.eks.dashboard_name
}


# =============================================================================
# ALARM OUTPUTS
# =============================================================================

output "cloudwatch_alarms" {
  description = "List of CloudWatch alarms names"
  value = {
    eks_nodes = try(aws_cloudwatch_metric_alarm.eks_nodes[0].alarm_name, null)
    rds_cpu = try(aws_cloudwatch_metric_alarm.rds_cpu[0].alarm_name, null)
    sqs_depth = try(aws_cloudwatch_metric_alarm.sqs_depth[0].alarm_name, null)
  }
}


# =============================================================================
# SNS OUTPUTS
# =============================================================================

output "sns_topic_arn" {
  description = "ARN of the SNS topick for alerts"
  value = try(aws_sns_topic.alerts[0].arn, null)
}


# =============================================================================
# IAM OUTPUTS
# =============================================================================

output "prometheus_role_arn" {
  description = "ARN of the Prometheus IAM role"
  value = try(aws_iam_role.prometheus[0].arn, null)
}

output "grafana_role_arn" {
  description = "ARN of the Grafana IAM role"
  value = try(aws_iam_role.grafana[0].arn, null)
}


# =============================================================================
# SUMMARY
# =============================================================================

output "monitoring_summary" {
  description = "Summary of monitoring resources"
  value = {
    # cloudwatch_dashboard = aws_cloudwatch_dashboard.ec2.dashboard_name
    log_groups = length(aws_cloudwatch_log_group.eks_cluster) + length(aws_cloudwatch_log_group.rds) + length(aws_cloudwatch_log_group.application)
    sns_alerts = var.enable_sns_alerts
    prometheus = var.enable_prometheus
    grafana = var.enable_grafana
    cloudwatch_alarms = var.enable_cloudwatch_alarms
  }
}