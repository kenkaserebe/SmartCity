# ===========================================================================
# S3 Module - Outputs
# ===========================================================================

# ===========================================================================
# SENSOR DATA BUCKET OUTPUTS
# ===========================================================================

output "sensor_data_bucket_id" {
  description   = "ID of the sensor data bucket"
  value         = aws_s3_bucket.sensor_data.id
}

output "sensor_data_bucket_arn" {
  description   = "ARN of the sensor data bucket"
  value         = aws_s3_bucket.sensor_data.arn
}

output "sensor_data_bucket_domain_name" {
  description   = "Domain name of the sensor data bucket"
  value         = aws_s3_bucket.sensor_data.bucket_domain_name
}


# ===========================================================================
# APPLICATION LOGS BUCKET OUTPUTS
# ===========================================================================

output "app_logs_bucket_id" {
  description   = "ID of the application logs bucket"
  value         = aws_s3_bucket.app_logs.id
}

output "app_logs_bucket_arn" {
  description   = "ARN of the application logs bucket"
  value         = aws_s3_bucket.app_logs.arn
}


# ===========================================================================
# STATIC ASSETS BUCKET OUTPUTS
# ===========================================================================

output "static_assets_bucket_id" {
  description   = "ID of the static assets bucket"
  value         = try(aws_s3_bucket.static_assets[0].id, null)
}

output "static_assets_bucket_arn" {
  description   = "ARN of the static assets bucket"
  value         = try(aws_s3_bucket.static_assets[0].arn, null)
}

output "static_assets_website_endpoint" {
  description   = "Website endpoint for static assets"
  value         = try(aws_s3_bucket_website_configuration.static_assets[0].website_endpoint, null)
}


# ===========================================================================
# IAM POLICY OUTPUTS
# ===========================================================================

output "iam_policy_arn" {
  description   = "ARN of the IAM policy for bucket access"
  value         = try(aws_iam_policy.s3_access[0].arn, null)
}

output "iam_policy_name" {
  description   = "Name of the IAM policy for bucket access"
  value         = try(aws_iam_policy.s3_access[0].name, null)
}


# ===========================================================================
# SUMMARY
# ===========================================================================

output "s3_summary" {
  description = "Summary of S3 resources"
  value = {
    sensor_data_bucket  = aws_s3_bucket.sensor_data.id
    app_logs_bucket     = aws_s3_bucket.app_logs.id
    static_assets       = var.enable_static_assets
    versioning          = var.enable_versioning
    iam_policy          = try(aws_iam_policy.s3_access[0].arn, null)
  }
}