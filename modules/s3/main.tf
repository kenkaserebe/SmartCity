# ===========================================================================
# S3 Module - SmartCity IoT Platform
# ===========================================================================
# Creates S3 buckets for:
# - Sensor data storage
# - Application logs
# - Static assets
# ===========================================================================

# ===========================================================================
# 1. SENSOR DATA BUCKET
# ===========================================================================
# Stores IoT sensor telemetry data from city sensors
# ===========================================================================

resource "aws_s3_bucket" "sensor_data" {
  bucket        = "${var.project_name}-${var.environment}-sensor-data"
  force_destroy = var.force_destroy

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-sensor-data"
    Environment = var.environment
    Component   = "storage"
    Service     = "sensor-data"
    DataType    = "iot-telemetry"
  })
}

# Block public access
resource "aws_s3_bucket_public_access_block" "sensor_data" {
  bucket                    = aws_s3_bucket.sensor_data.id
  block_public_acls         = true
  block_public_policy       = true
  ignore_public_acls        = true
  restrict_public_buckets   = true
}

# Enable versioning
resource "aws_s3_bucket_versioning" "sensor_data" {
  bucket = aws_s3_bucket.sensor_data.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "sensor_data" {
  bucket = aws_s3_bucket.sensor_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Lifecycle rules for sensor data
# - Move to Standard-IA after 30 days
# - Move to Glacier after 90 days
# - Expire after 365 days
resource "aws_s3_bucket_lifecycle_configuration" "sensor_data" {
  bucket = aws_s3_bucket.sensor_data.id

  rule {
    id      = "transition-sensor-data"
    status  = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}


# ===========================================================================
# 2. APPLICATION LOGS BUCKET
# ===========================================================================
# Storage logs from EKS pods and application
# ===========================================================================

resource "aws_s3_bucket" "app_logs" {
  bucket        = "${var.project_name}-${var.environment}-app-logs"
  force_destroy = var.force_destroy

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-app-logs"
    Environment = var.environment
    Component   = "storage"
    Service     = "application-logs"
  })
}

# Block public access
resource "aws_s3_bucket_public_access_block" "app_logs" {
  bucket                    = aws_s3_bucket.app_logs.id
  block_public_acls         = true
  block_public_policy       = true
  ignore_public_acls        = true
  restrict_public_buckets   = true
}

# Enable versioning
resource "aws_s3_bucket_versioning" "app_logs" {
  bucket = aws_s3_bucket.app_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "app_logs" {
  bucket = aws_s3_bucket.app_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Lifecycle rules for logs
# - Expire after 90 days
resource "aws_s3_bucket_lifecycle_configuration" "app_logs" {
  bucket = aws_s3_bucket.app_logs.id

  rule {
    id      = "expire-logs"
    status  = "Enabled"

    expiration {
      days = 90
    }
  }

  # Expire old version after 30 days
  rule {
    id      = "expire-old-log-versions"
    status  = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}


# ===========================================================================
# 3. STATIC ASSETS BUCKET
# ===========================================================================

resource "aws_s3_bucket" "static_assets" {
  count         = var.enable_static_assets ? 1 : 0

  bucket        = var.static_assets_bucket_name != "" ? var.static_assets_bucket_name : "${var.project_name}-${var.environment}-static-assets"
  force_destroy = var.force_destroy

  tags = merge(var.common_tags, {
    Name            = "${var.project_name}-${var.environment}-static-assets"
    Environment     = var.environment
    Component       = "storage"
    Service         = "static-assets"
  })
}

# Block public access (These need to be public)
resource "aws_s3_bucket_public_access_block" "static_assets" {
  count                     = var.enable_static_assets ? 1 : 0

  bucket                    = aws_s3_bucket.static_assets[0].id
  block_public_acls         = false
  block_public_policy       = false
  ignore_public_acls        = false
  restrict_public_buckets   = false
}

# Enable versioning
resource "aws_s3_bucket_versioning" "static_assets" {
  count     = var.enable_static_assets ? 1 : 0

  bucket    = aws_s3_bucket.static_assets.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Website hosting for static assets
resource "aws_s3_bucket_website_configuration" "static_assets" {
  count     = var.enable_static_assets && var.static_assets_website_hosting ? 1 : 0

  bucket    = aws_s3_bucket.static_assets[0].id

  index_document {
    suffix = var.static_assets_index_document
  }

  error_document {
    key = var.static_assets_error_document
  }
}

# Public read policy for static assets
resource "aws_s3_bucket_policy" "static_assets" {
  count     = var.enable_static_assets && var.static_assets_public_read ? 1 : 0

  bucket    = aws_s3_bucket.static_assets[0].id

  policy = jsonencode({
    Version     = "2012-10-17"
    Statement   = [
        {
            Sid         = "PublicReadGetObject"
            Effect      = "Allow"
            Principal   = "*"
            Action      = "s3:GetObject"
            Resource    = "arn:aws:s3::${aws_s3_bucket.static_assets[0].id}/*"
        }
    ]
  })
}


# ===========================================================================
# 4. IAM POLICY FOR BUCKET ACCESS
# ===========================================================================
# This policy can be attached to EKS nodes or IRSA roles
# ===========================================================================

resource "aws_iam_policy" "s3_access" {
  count         = var.create_iam_policy ? 1 : 0

  name          = "${var.project_name}-${var.environment}-s3-access-policy"
  description   = "S3 bucket access policy for SmartCity application"

  policy = jsonencode({
    Version     = "2012-10-17"
    Statement   = [
        # List buckets
        {
            Effect = "Allow"
            Action = [
                "s3:ListBucket",
                "s3:GetBucketLocation"
            ]
            Resource = [
                aws_s3_bucket.sensor_data.arn,
                aws_s3_bucket.app_logs.arn,
                var.enable_static_assets ? aws_s3_bucket.static_assets[0].arn : "${aws_s3_bucket.sensor_data.arn}-static"
            ]
        },
        # Read/Write sensor data
        {
            Effect = "Allow"
            Action = [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:GetObjectVersion",
                "s3:PutObjectAcl"
            ]
            Resource = [
                "${aws_s3_bucket.sensor_data.arn}/*",
                "${aws_s3_bucket.app_logs.arn}/*"
            ]
        },
        # Read-only for static assets
        {
            Effect = "Allow"
            Action = [
                "s3:GetObject",
                "s3:GetObjectVersion"
            ]
            Resource = var.enable_static_assets ? [
                "${aws_s3_bucket.static_assets[0].arn}/*"
            ] : []
        }
    ]
  })
}


# ===========================================================================
# 5. DATA SOURCES
# ===========================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
