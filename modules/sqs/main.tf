# SmartCity/modules/sqs/main.tf

terraform {
  backend "s3" {}
}

# =============================================================================
# SQS Module - SmartCity IoT Platform
# =============================================================================
# Creates SQS queues for:
# - Sensor data ingestion
# - Event processing
# - Dead-letter queue (DLQ) for failed messages
# - FIFO queues for ordered processing (if needed)
# =============================================================================


# =============================================================================
# 1. PRIMARY QUEUE - Main Application Queue
# =============================================================================

resource "aws_sqs_queue" "main" {
    name                        = "${var.project_name}-${var.environment}-queue"
    fifo_queue                  = var.fifo_queue
    content_based_deduplication = var.fifo_queue ? var.content_based_deduplication : null
    deduplication_scope         = var.fifo_queue ? var.deduplication_scope : null
    fifo_throughput_limit       = var.fifo_queue ? var.fifo_throughput_limit : null

    # Queue Configuration
    delay_seconds               = var.delay_seconds
    max_message_size            = var.max_message_size
    message_retention_seconds   = var.message_retention_seconds
    receive_wait_time_seconds   = var.receive_wait_time_seconds
    visibility_timeout_seconds  = var.visibility_timeout_seconds

    # Dead-Letter Queue (DLQ)
    redrive_policy  = var.enable_dlq ? jsonencode({
        deadLetterTargetArn = aws_sqs_queue.dlq[0].arn
        maxReceiveCount     = var.max_receive_count
    }) : null

    # Server-Side Encryption
    kms_master_key_id                   = var.kms_key_arn != "" ? var.kms_key_arn : "alias/aws/sqs"
    kms_data_key_reuse_period_seconds   = var.kms_data_key_reuse_period_seconds

    # Tags
    tags = merge(var.common_tags, {
        Name        = "${var.project_name}-${var.environment}-queue"
        Environment = var.environment
        Component   = "messaging"
        Service     = "sqs"
    })
}


# =============================================================================
# 2. DEAD-LETTER QUEUE (DLQ)
# =============================================================================
# Handles messages that failed processing
# =============================================================================

resource "aws_sqs_queue" "dlq" {
    count                       = var.enable_dlq ? 1 : 0

    name                        = "${var.project_name}-${var.environment}-dlq"
    fifo_queue                  = var.fifo_queue

    # Longer retention for failed messages
    message_retention_seconds   = var.dlq_message_retention_seconds
    max_message_size            = var.max_message_size
    receive_wait_time_seconds   = var.receive_wait_time_seconds
    visibility_timeout_seconds  = var.visibility_timeout_seconds

    # Server-Side Encryption
    kms_master_key_id                   = var.kms_key_arn != "" ? var.kms_key_arn : "alias/aws/sqs"
    kms_data_key_reuse_period_seconds   = var.kms_data_key_reuse_period_seconds

    tags = merge(var.common_tags, {
        Name        = "${var.project_name}-${var.environment}-dlq"
        Environment = var.environment
        Component   = "messaging"
        Service     = "sqs"
        Type        = "dead-letter"
    })
}


# =============================================================================
# 3. SENSOR DATA QUEUE (Optional - Separate queue for IoT sensor data)
# =============================================================================

resource "aws_sqs_queue" "sensor_data" {
    count = var.enable_sensor_queue ? 1 : 0

    name                        = "${var.project_name}-${var.environment}-sensor-queue"
    fifo_queue                  = var.sensor_fifo_queue
    content_based_deduplication = var.sensor_fifo_queue ? var.content_based_deduplication : null

    # Queue Configuration
    delay_seconds               = var.sensor_delay_seconds
    max_message_size            = var.sensor_max_message_size
    message_retention_seconds   = var.sensor_message_retention_seconds
    receive_wait_time_seconds   = var.receive_wait_time_seconds
    visibility_timeout_seconds  = var.sensor_visibility_timeout_seconds

    # Dead-Letter Queue (DLQ)
    redrive_policy = var.enable_dlq ? jsonencode({
        deadLetterTargetArn = aws_sqs_queue.sensor_dlq[0].arn
        maxReceiveCount     = var.sensor_max_receive_count
    }) : null

    # Server-Side Encryption
    kms_master_key_id                   = var.kms_key_arn != "" ? var.kms_key_arn : "alias/aws/sqs"
    kms_data_key_reuse_period_seconds   = var.kms_data_key_reuse_period_seconds

    tags = merge(var.common_tags, {
        Name        = "${var.project_name}-${var.environment}-sensor-queue"
        Environment = var.environment
        Component   = "messaging"
        Service     = "sqs"
        Type        = "sensor-date"
    })
}

# Sensor DLQ
resource "aws_sqs_queue" "sensor_dlq" {
    count                               = var.enable_sensor_queue && var.enable_dlq ? 1 : 0

    name                                = "${var.project_name}-${var.environment}-sensor-dlq"
    fifo_queue                          = var.sensor_fifo_queue
    message_retention_seconds           = var.dlq_message_retention_seconds
    max_message_size                    = var.sensor_max_message_size
    receive_wait_time_seconds           = var.receive_wait_time_seconds
    visibility_timeout_seconds          = var.sensor_visibility_timeout_seconds
    kms_master_key_id                   = var.kms_key_arn != "" ? var.kms_key_arn : "alias/aws/sqs"
    kms_data_key_reuse_period_seconds   = var.kms_data_key_reuse_period_seconds

    tags = merge(var.common_tags, {
        Name        = "${var.project_name}-${var.environment}-sensor-dlq"
        Environment = var.environment
        Component   = "messaging"
        Service     = "sqs"
        Type        = "sensor-dead-letter"
    })
}


# =============================================================================
# 4. QUEUE POLICIES
# =============================================================================
# Allow specific services (like EKS nodes) to access the queues
# =============================================================================

# Main queue policy
resource "aws_sqs_queue_policy" "main" {
    count       = var.enable_queue_policy ? 1 : 0

    queue_url   = aws_sqs_queue.main.id

    policy = jsonencode({
        Version     = "2012-10-17"
        Statement   = [
            # Allow EKS nodes to send/receive messages
            {
                Sid         = "AllowEKSNodes"
                Effect      = "Allow"
                Principal   = {
                    AWS = var.allowed_principals
                }
                Action = [
                    "sqs:SendMessage",
                    "sqs:ReceiveMessage",
                    "sqs:DeleteMessage",
                    "sqs:GetQueueAttributes",
                    "sqs:GetQueueUrl",
                    "sqs:ChangeMessageVisibility"
                ]
                Resource = aws_sqs_queue.main.arn
            },
            # Allow CloudWatch to monitor the queue
            {
                Sid         = "AllowCloudWatch"
                Effect      = "Allow"
                Principal   = {
                    Service = "cloudwatch.amazonaws.com"
                }
                Action = [
                    "sqs:GetQueueAttributes"
                ]
                Resource = aws_sqs_queue.main.arn
            }
        ]
    })
}

# Sensor queue policy
resource "aws_sqs_queue_policy" "sensor" {
    count       = var.enable_sensor_queue && var.enable_queue_policy ? 1 : 0

    queue_url   = aws_sqs_queue.sensor_data[0].id

    policy      = jsonencode({
        Version     = "2012-10-17"
        Statement   = [
            # Allow IoT services to send sensor data
            {
                Sid         = "AllowIoTServices"
                Effect      = "Allow"
                Principal   = {
                    AWS = var.sensor_allowed_principals
                }
                Action = [
                    "sqs:SendMessage",
                    "sqs:GetQueueAttributes",
                    "sqs:GetQueueUrl"
                ]
                Resource = aws_sqs_queue.sensor_data[0].arn
            }
        ]
    })
}


# =============================================================================
# 5. IAM POLICY FOR QUEUE ACCESS
# =============================================================================
# This policy can be attached to EKS nodes or IRSA roles
# =============================================================================

resource "aws_iam_policy" "queue_access" {
    count       = var.create_iam_policy ? 1 : 0

    name        = "${var.project_name}-${var.environment}-sqs-policy"
    description = "SQS queue access policy for SmartCity application"

    policy = jsonencode({
        Version     = "2012-10-17"
        Statement   = [
            {
                Effect = "Allow"
                Action = [
                    "sqs:ListQueues",
                    "sqs:GetQueueUrl"
                ]
                Resource = "*"
            },
            {
                Effect = "Allow"
                Action = [
                    "sqs:SendMessage",
                    "sqs:SendMessageBatch",
                    "sqs:ReceiveMessage",
                    "sqs:DeleteMessage",
                    "sqs:DeleteMessageBatch",
                    "sqs:ChangeMessageVisibility",
                    "sqs:ChangeMessageVisisbilityBatch",
                    "sqs:GetQueueAttributes"
                ]
                Resource = [
                    aws_sqs_queue.main.arn,
                    var.enable_dlq ? aws_sqs_queue.dlq[0].arn : "${aws_sqs_queue.main.arn}-dlq"
                ]
            }
        ]
    })
}


# =============================================================================
# 6. S3 NOTIFICATIONS (Trigger SQS from S3 events)
# =============================================================================

resource "aws_s3_bucket_notification" "s3_to_sqs" {
    count   = var.enable_s3_notifications ? 1 : 0

    bucket  = var.s3_bucket_id

    queue {
        queue_arn       = aws_sqs_queue.main.arn
        events          = var.s3_events
        filter_suffix   = var.s3_filter_suffix
        filter_prefix   = var.s3_filter_prefix
    }
}


# =============================================================================
# 7. CLOUDWATCH METRICS AND ALARMS
# =============================================================================

# CloudWatch metric alarm for queue depth
resource "aws_cloudwatch_metric_alarm" "queue_depth" {
    count               = var.enable_cloudwatch_alarms ? 1 : 0

    alarm_name          = "${var.project_name}-${var.environment}-sqs-queue-depth"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = "2"
    metric_name         = "ApproximateNumberOfMessagesVisible"
    namespace           = "AWS/SQS"
    period              = "300"
    statistic           = "Average"
    threshold           = var.queue_depth_threshold
    alarm_description   = "This metric monitors queue depth and alerts when it exceeds the threshold"
    alarm_actions       = var.alarm_actions

    dimensions = {
      QueueName = aws_sqs_queue.main.name
    }

    tags = merge(var.common_tags, {
        Name        = "${var.project_name}-${var.environment}-sqs-queue-depth"
        Environment = var.environment
        Component   = "monitoring"
        Service     = "sqs"
    })
}

# CloudWatch metric alarm for DLQ messages
resource "aws_cloudwatch_metric_alarm" "dlq_depth" {
  count                 = var.enable_cloudwatch_alarms && var.enable_dlq ? 1 : 0

  alarm_name            = "${var.project_name}-${var.environment}-sqs-dlq-depth"
  comparison_operator   = "GreaterThanThreshold"
  evaluation_periods    = "2"
  metric_name           = "ApproximateNumberOfMessagesVisible"
  namespace             = "AWS/SQS"
  period                = "300"
  statistic             = "Average"
  threshold             = var.dlq_depth_threshold
  alarm_description     = "This metric monitors DLQ depth and alerts when messages are being sent to DLQ"
  alarm_actions         = var.alarm_actions

  dimensions = {
    QueueName = aws_sqs_queue.dlq[0].name
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-sqs-dlq-depth"
    Environment = var.environment
    Component   = "monitoring"
    Service     = "sqs"
    Type        = "dead-letter"
  })
}


# =============================================================================
# 8. DATA SOURCES
# =============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

