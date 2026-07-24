# SmartCity/global/backend/main.tf

terraform {
  # No backend block Terraform defaults to local state
}

provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "terraform_state" {
  bucket        = var.bucket_name
  force_destroy = true      # This deletes even when the bucket contains something
}

# Server-side encryption protects sensitive data in state files
resource "aws_s3_bucket_server_side_encryption_configuration" "name" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Ensure the bucket blocks all public access
resource "aws_s3_bucket_public_access_block" "block" {
  bucket                    = aws_s3_bucket.terraform_state.id

  block_public_acls         = true
  block_public_policy       = true
  ignore_public_acls        = true
  restrict_public_buckets   = true
}