# ECR Module Variables

variable "project_name" {
  description = "Name of the project, used for repository naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

# Image Configuration
variable "image_tag_mutability" {
  description = "The tag mutability setting for the repository. Must be MUTABLE or IMMUTABLE"
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be either MUTABLE or IMMUTABLE"
  }
}

variable "scan_on_push" {
  description = "Enable image scanning on push"
  type        = bool
  default     = true
}

# Encryption Configuration
variable "encryption_type" {
  description = "The encryption type for the repository. Must be AES256 or KMS"
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_type)
    error_message = "encryption_type must be either AES256 or KMS"
  }
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for encryption (required if encryption_type is KMS)"
  type        = string
  default     = null
}

# Lifecycle Policy Configuration
variable "max_image_count" {
  description = "Maximum number of tagged release images to keep"
  type        = number
  default     = 30
}

variable "max_dev_image_count" {
  description = "Maximum number of dev/feature branch images to keep"
  type        = number
  default     = 10
}

variable "untagged_image_expiry_days" {
  description = "Number of days after which untagged images expire"
  type        = number
  default     = 7
}

variable "sha_image_expiry_days" {
  description = "Number of days after which SHA-tagged images expire"
  type        = number
  default     = 30
}

# Cross-Account Access Configuration
variable "enable_cross_account_access" {
  description = "Enable cross-account access to ECR repositories"
  type        = bool
  default     = false
}

variable "cross_account_arns" {
  description = "List of AWS account ARNs allowed to pull images"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
