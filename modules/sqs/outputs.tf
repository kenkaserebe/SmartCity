# =============================================================================
# SQS Module - Outputs
# =============================================================================

# =============================================================================
# MAIN QUEUE OUTPUTS
# =============================================================================

output "main_queue_id" {
  description   = "ID of the main queue"
  value         = aws_sqs_queue.main.id
}

output "main_queue_arn" {
  description   = "ARN of the main queue"
  value         = aws_sqs_queue.main.arn
}

output "main_queue_url" {
  description   = "URL of the main queue"
  value         = aws_sqs_queue.main.url
}

output "main_queue_name" {
  description   = "Name of the main queue"
  value         = aws_sqs_queue.main.name
}


# =============================================================================
# DLQ OUTPUTS
# =============================================================================

output "dlq_id" {
  description   = "ID of the dead-letter queue"
  value         = try(aws_sqs_queue.dlq[0].id, null)
}

output "dlq_arn" {
  description   = "ARN of the dead-letter queue"
  value         = try(aws_sqs_queue.dlq[0].arn, null)
}

output "dlq_url" {
  description   = "URL of the dead-letter queue"
  value         = try(aws_sqs_queue.dlq[0].url, null)
}


# =============================================================================
# SENSOR QUEUE OUTPUTS
# =============================================================================

output "sensor_queue_id" {
  description   = "ID of the sensor queue"
  value         = try(aws_sqs_queue.sensor_data[0].id, null)
}

output "sensor_queue_arn" {
  description   = "ARN of the sensor queue"
  value         = try(aws_sqs_queue.sensor_data[0].arn, null)
}

output "sensor_queue_url" {
  description   = "URL of the sensor queue"
  value         = try(aws_sqs_queue.sensor_data[0].url, null)
}

output "sensor_dlq_id" {
  description   = "ID of the sensor DLQ"
  value         = try(aws_sqs_queue.sensor_dlq[0].id, null)
}

output "sensor_dlq_arn" {
  description   = "ARN of the sensor DLQ"
  value         = try(aws_sqs_queue.sensor_dlq[0].arn, null)
}


# =============================================================================
# IAM POLICY OUTPUTS
# =============================================================================

output "iam_policy_arn" {
  description   = "ARN of the IAM policy for queue access"
  value         = try(aws_iam_policy.queue_access[0].arn, null)
}

output "iam_policy_name" {
  description   = "Name of the IAM policy for queue access"
  value         = try(aws_iam_policy.queue_access[0].name, null)
}


# =============================================================================
# CLOUDWATCH ALARMS
# =============================================================================

output "queue_depth_alarm_name" {
  description   = "Name of the queue depth CloudWatch alarm"
  value         = try(aws_cloudwatch_metric_alarm.queue_depth[0].alarm_name, null)
}

output "dlq_depth_alarm_name" {
  description   = "Name of the DLQ depth CloudWatch alarm"
  value         = try(aws_cloudwatch_metric_alarm.dlq_depth[0].alarm_name, null)
}



# =============================================================================
# SUMMARY
# =============================================================================

output "sqs_summary" {
  description = "Summary of SQS resources"
  value = {
    main_queue_name = aws_sqs_queue.main.name
    main_queue_arn  = aws_sqs_queue.main.arn
    dlq_enabled     = var.enable_dlq
    dlq_arn         = try(aws_sqs_queue.dlq[0].arn, null)
    fifo_queue      = var.fifo_queue
    sensor_queue    = var.enable_sensor_queue
    alarms_enabled  = var.enable_cloudwatch_alarms
  }
}