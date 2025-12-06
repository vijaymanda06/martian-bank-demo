# Input Variables for Martian Bank Infrastructure

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-west-1"
}

variable "project_name" {
  description = "Name of the project, used for resource naming"
  type        = string
  default     = "martianbank"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["us-west-1a", "us-west-1c"]
}

# EKS Configuration
variable "cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.31"
}

variable "cluster_endpoint_public_access" {
  description = "Enable public access to EKS cluster endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks allowed to access the public endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "auto_mode_node_pools" {
  description = "List of Auto Mode node pools. Options: general-purpose, system"
  type        = list(string)
  default     = ["general-purpose", "system"]
}

variable "enable_network_policy" {
  description = "Enable network policy support in VPC CNI"
  type        = bool
  default     = true
}

variable "cluster_enabled_log_types" {
  description = "List of control plane logging to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

# GitHub OIDC Configuration
variable "github_org" {
  description = "GitHub organization name for OIDC trust policy"
  type        = string
  default     = ""
}

variable "github_repo" {
  description = "GitHub repository name for OIDC trust policy"
  type        = string
  default     = ""
}

# Secrets Configuration
variable "mongodb_uri" {
  description = "MongoDB connection URI (stored in Secrets Manager)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "jwt_secret" {
  description = "JWT signing secret (stored in Secrets Manager)"
  type        = string
  sensitive   = true
  default     = ""
}

# ECR Configuration
variable "ecr_image_tag_mutability" {
  description = "The tag mutability setting for ECR repositories (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "MUTABLE"
}

variable "ecr_scan_on_push" {
  description = "Enable image scanning on push for ECR repositories"
  type        = bool
  default     = true
}

variable "ecr_max_image_count" {
  description = "Maximum number of tagged release images to keep in ECR"
  type        = number
  default     = 30
}

variable "ecr_max_dev_image_count" {
  description = "Maximum number of dev/feature branch images to keep in ECR"
  type        = number
  default     = 10
}

variable "ecr_untagged_image_expiry_days" {
  description = "Number of days after which untagged images expire in ECR"
  type        = number
  default     = 7
}

variable "ecr_sha_image_expiry_days" {
  description = "Number of days after which SHA-tagged images expire in ECR"
  type        = number
  default     = 30
}
