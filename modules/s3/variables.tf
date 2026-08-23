# ===========================================================================
# S3 Module - Variables
# ===========================================================================

# ===========================================================================
# REQUIRED VARIABLES
# ===========================================================================

variable "environment" {
  description   = "Environment name (dev, staging, prod)"
  type          = string

  validation {
    condition       = contains(["dev", "staging", "prod"], var.environment)
    error_message   = "Environment must be one of: dev, staging, prod."
  }
}


# ===========================================================================
# OPTIONAL VARIABLES WITH DEFAULTS
# ===========================================================================

variable "project_name" {
  description   = "Project name used for naming resources"
  type          = string
}

variable "common_tags" {
  description   = "Common tags applied to all resources"
  type          = map(string)
  default       = {}
}

variable "force_destroy" {
  description   = "Force destroy bucket even if not empty (use with caution)"
  type          = bool
}

variable "enable_versioning" {
  description   = "Enable versioning on sensor data bucket"
  type          = bool
}

variable "create_iam_policy" {
  description   = "Create an IAM policy for bucket access"
  type          = bool
}


# ===========================================================================
# STATIC ASSETS CONFIGURATION
# ===========================================================================

variable "enable_static_assets" {
  description   = "Enable static assets bucket"
  type          = bool
}

variable "static_assets_bucket_name" {
  description   = "Name of the static assets bucket (defaults to project-environment-static-assets)"
  type          = string
  default       = ""
}

variable "static_assets_website_hosting" {
  description   = "Enable website hosting for static assets"
  type          = bool
  default       = false
}

variable "static_assets_public_read" {
  description   = "Allow public read access to static assets"
  type          = bool
  default       = false
}

variable "static_assets_index_document" {
  description   = "Index document for static website"
  type          = string
  default       = "index.html"
}

variable "static_assets_error_document" {
  description   = "Error document for static website"
  type          = string
  default       = "error.html"
}
