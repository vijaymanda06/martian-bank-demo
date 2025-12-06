# Secrets Module Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

# MongoDB Configuration
variable "mongodb_uri" {
  description = "MongoDB connection URI"
  type        = string
  sensitive   = true
  default     = ""
}

variable "mongodb_database" {
  description = "MongoDB database name"
  type        = string
  default     = "bank"
}

variable "mongodb_username" {
  description = "MongoDB username"
  type        = string
  sensitive   = true
  default     = ""
}

variable "mongodb_password" {
  description = "MongoDB password"
  type        = string
  sensitive   = true
  default     = ""
}

# JWT Configuration
variable "jwt_secret" {
  description = "JWT signing secret"
  type        = string
  sensitive   = true
  default     = ""
}

variable "jwt_expiry" {
  description = "JWT token expiry duration"
  type        = string
  default     = "24h"
}

# Secret Rotation Configuration (Optional)
variable "enable_secret_rotation" {
  description = "Enable automatic secret rotation"
  type        = bool
  default     = false
}

variable "rotation_lambda_arn" {
  description = "ARN of the Lambda function for secret rotation"
  type        = string
  default     = ""
}

variable "rotation_days" {
  description = "Number of days between automatic secret rotations"
  type        = number
  default     = 30
}

variable "recovery_window_in_days" {
  description = "Number of days before a deleted secret is permanently removed (0 for immediate, 7-30 for delayed)"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
