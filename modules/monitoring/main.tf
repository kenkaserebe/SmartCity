# =============================================================================
# Monitoring Module - SmartCity IoT Platform
# =============================================================================
# Creates:
# - CloudWatch Log Groups and Dashboards
# - Prometheus metrics collection
# - Grafana dashboards
# - Alertmanager for notifications
# - Service monitors for applications
# =============================================================================

# =============================================================================
# 1. CLOUDWATCH LOG GROUPS
# =============================================================================
# Centralized logging for all components
# =============================================================================

# EKS Cluster Logs
resource "aws_cloudwatch_log_group" "eks_cluster" {
  name = "/aws/eks/${var.project_name}-${var.environment}-cluster"
  retention_in_days = var.cloudwatch_log_retention

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-eks-cluster-logs"
    Environment = var.environment
    Component = "monitoring"
    Service = "cloudwatch"
  })
}

# RDS Logs
resource "aws_cloudwatch_log_group" "rds" {
  name = "/aws/rds/${var.project_name}-${var.environment}-postgres"
  retention_in_days = var.cloudwatch_log_retention

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-rds-logs"
    Environment = var.environment
    Component = "monitoring"
    Service = "cloudwatch"
  })
}

# Application Logs (from EKS pods)
resource "aws_cloudwatch_log_group" "application" {
  name = "/aws/application/${var.project_name}-${var.environment}"
  retention_in_days = var.cloudwatch_log_retention

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-application-logs"
    Environment = var.environment
    Component = "monitoring"
    Service = "cloudwatch"
  })
}


# =============================================================================
# 2. CLOUDWATCH DASHBOARDS
# =============================================================================
# Custom dashboards for observability
# =============================================================================

resource "aws_cloudwatch_dashboard" "eks" {
  dashboard_name = "${var.project_name}-${var.environment}-eks"

  dashboard_body = jsonencode({
    widgets = [
        {
            type = "metric"
            properties = {
                metrics = [
                    ["AWS/EKS", "cluster_failed_request_count", "cluster_name", aws_eks_cluster.mani.name],
                    ["AWS/EKS", "node_group_node_count", "cluster_name", aws_eks_cluster.main.name]
                ]
                period = 300
                stat = "Average"
                region = var.region
                title = "EKS Cluster Metrics"
                view = "timeSeries"
                stacked = false
            }
        },
        {
            type = "metric"
            properties = {
                metrics = [
                    ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", var.rds_instance_id],
                    ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.rds_instance_id],
                    ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", var.rds_instance_id]
                ]
                period = 300
                stat = "Average"
                region = var.region
                title = "RDS Metrics"
                view = "timeSeries"
                stacked = false
            }
        },
        {
            type = "metric"
            properties = {
                metrics = [
                    ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", var.sqs_queue_name],
                    ["AWS/SQS", "ApproximateNumberOfMessagesNotVisible", "QueueName", var.sqs_queue_name],
                    ["AWS/SQS", "ApproximateNumberOfMessagesDelayed", "QueueName", var.sqs_queue_name]
                ]
                period = 300
                stat = "Average"
                region = var.region
                title = "SQS Queue Metrics"
                view = "timeSeries"
                stacked = false
            }
        }
    ]
  })
}


# =============================================================================
# 3. CLOUDWATCH METRIC ALARMS
# =============================================================================
# Proactive monitoring alerts
# =============================================================================

# EKS Cluster Health
resource "aws_cloudwatch_metric_alarm" "eks_nodes" {
  count = var.enable_cloudwatch_alarms ? 1 : 0

  alarm_name = "${var.project_name}-${var.environment}-eks-nodes"
  comparison_operator = "LessThanThreshold"
  evaluation_periods = "2"
  metric_name = "node_group_node_count"
  namespace = "AWS/EKS"
  period = "300"
  statistic = "Average"
  threshold = var.eks_min_nodes
  alarm_description = "EKS node count dropped below minimum"
  alarm_actions = var.alarm_actions

  dimensions = {
    cluster_name = aws_eks_cluster.main.name
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-eks-nodes"
    Environment = var.environment
    Component = "monitoring"
    Service = "alarms"
  })
}

# RDS CPU Utilization
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  count = var.enable_cloudwatch_alarms && var.rds_instance_id != "" ? 1 : 0

  alarm_name = "${var.project_name}-${var.environment}-rds-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/RDS"
  period = "300"
  statistic = "Average"
  threshold = var.rds_cpu_threshold
  alarm_description = "RDS CPU utilization exceeded threshold"
  alarm_actions = var.alarm_actions

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-rds-cpu"
    Environment = var.environment
    Component = "monitoring"
    Service = "alarms"
  })
}

# SQS Queue Depth
resource "aws_cloudwatch_metric_alarm" "sqs_depth" {
  count = var.enable_cloudwatch_alarms && var.sqs_queue_url != "" ? 1 : 0

  alarm_name = "${var.project_name}-${var.environment}-sqs-depth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = "2"
  metric_name = "ApproximateNumberOfMessagesVisible"
  namespace = "AWS/SQS"
  period = "300"
  statistic = "Average"
  threshold = var.sqs_depth_threshold
  alarm_description = "SQS queue depth exceeded threshold"
  alarm_actions = var.alarm_actions

  dimensions = {
    QueueName = var.sqs_queue_name
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-sqs-depth"
    Environment = var.environment
    Component = "monitoring"
    Service = "alarms"
  })
}


# =============================================================================
# 4. PROMETHEUS CONFIGURATION
# =============================================================================
# Prometheus will be deployed via Helm on EKS
# This creates the necessary IAM roles and resources
# =============================================================================

# IAM Role for Prometheus (IRSA)
resource "aws_iam_role" "prometheus" {
  count = var.enable_prometheus ? 1 : 0

  name = "${var.project_name}-${var.environment}-prometheus-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement =[{
        Effect = "Allow"
        Principal = {
            Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
            StringEquals = {
                "${var.oidc_issuer_url}:sub" = "system:serviceaccount:monitoring:prometheus"
            }
        }
    }]
  })

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-prometheus-role"
    Environment = var.environment
    Component = "monitoring"
    Service = "prometheus"
  })
}

# Premetheus Policy - Allow scraping and storing metrics
resource "aws_iam_policy" "prometheus" {
  count = var.enable_prometheus ? 1 : 0

  name = "${var.project_name}-${var.environment}-prometheus-policy"
  description = "Prometheus metrics collection policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Effect = "Allow"
            Action = [
                "sts:AssumeRole",
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceTypes",
                "ec2:DescribeTags",
                "ec2:DescribeRegions",
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeLaunchConfigurations",
                "autoscaling:DescribeTags",
                "eks:DescribeCluster",
                "eks:ListNodegroups"
            ]
            Resource = "*"
        },
        {
            Effect = "Allow"
            Action = [
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:ListBucket"
            ]
            Resource = [
                var.prometheus_s3_bucket != "" ? "arn:aws:s3:::${var.prometheus_s3_bucket}" : "arn:aws:s3:::${var.project_name}-${var.environment}-prometheus",
                var.prometheus_s3_bucket != "" ? "arn:aws:s3:::${var.prometheus_s3_bucket}/*" : "arn:aws:s3:::${var.project_name}-${var.environment}-prometheus/*"
            ]
        }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "prometheus" {
  count = var.enable_prometheus ? 1 : 0

  policy_arn = aws_iam_policy.prometheus[0].arn
  role = aws_iam_role.prometheus[0].name
}


# =============================================================================
# 5. GRAFANA CONFIGURATION
# =============================================================================
# Grafana will be deployed via Helm on EKS
# This creates the necessary resources
# =============================================================================

# IAM Role for Grafana (IRSA)
resource "aws_iam_role" "grafana" {
  count = var.enable_grafana ? 1 : 0

  name = "${var.project_name}-${var.environment}-grafana-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
        Effect = "Allow"
        Principal = {
            Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
            StringEquals = {
                "${var.oidc_issuer_url}:sub" = "system:serviceaccount:monitoring:grafana"
            }
        }
    }]
  })
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-grafana-role"
    Environment = var.environment
    Component = "monitoring"
    Service = "grafana"
  })
}

# Grafana Policy - Allow querying CloudWatch and reading dashboards
resource "aws_iam_policy" "grafana" {
  count = var.enable_grafana ? 1 : 0

  name =  "${var.project_name}-${var.environment}-grafana-policy"
  description = "Grafana CloudWatch query policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Effect = "Allow"
            Action = [
                "cloudwatch:GetMetricData",
                "cloudwatch:GetMetricStatistics",
                "cloudwatch:ListMetrics",
                "cloudwatch:DescribeAlarms",
                "logs:DescribeLogGroups",
                "logs:GetLogEvents",
                "logs:FilterLogEvents",
                "ec2:DescribeInstances",
                "ec2:DescribeTags",
                "autoscaling:DescribeAutoScalingGroups"
            ]
            Resource = "*"
        }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "grafana" {
  count = var.enable_grafana ? 1 : 0

  policy_arn = aws_iam_policy.grafana[0].arn
  role = aws_iam_role.grafana[0].name
}


# =============================================================================
# 6. SNS TOPIC FOR ALERTS
# =============================================================================
# Notification system for alerts
# =============================================================================

resource "aws_sns_topic" "alerts" {
  count = var.enable_sns_alerts ? 1 : 0

  name = "${var.project_name}-${var.environment}-alerts"

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-alerts"
    Environment = var.environment
    Component = "monitoring"
    Service = "sns"
  })
}

# Email subscription
resource "aws_sns_topic_subscription" "email" {
  count = var.enable_sns_alerts && var.alert_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.alerts[0].arn
  protocol = "email"
  endpoint = var.alert_email
}

# Slack subcription (requires SNS to Slack integration)
resource "aws_sns_topic_subscription" "slack" {
  count = var.enable_sns_alerts && var.alert_slack_webhook != "" ? 1 : 0

  topic_arn = aws_sns_topic.alerts[0].arn
  protocol = "https"
  endpoint = var.alert_slack_webhook
}


# =============================================================================
# 7. DATA SOURCES
# =============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# EKS Cluster Data Source (if cluster exists)
data "aws_eks_cluster" "main" {
  name = "${var.project_name}-${var.environment}-eks-cluster"
}
