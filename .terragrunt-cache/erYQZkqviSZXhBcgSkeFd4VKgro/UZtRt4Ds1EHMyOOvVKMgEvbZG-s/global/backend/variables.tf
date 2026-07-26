# SmartCity/global/backend/variables.tf

variable "region" {
  description   = "AWS region"
  type          = string
}

variable "bucket_name" {
  description   = "Globally unique S3 bucket name"
  type          = string
}