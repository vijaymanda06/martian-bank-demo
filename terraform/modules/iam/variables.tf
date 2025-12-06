# IAM Module Variables
#
# Requirements: 6.2, 6.3, 6.4, 9.3, 9.4

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "eks_oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider"
  type        = string
}

variable "eks_oidc_issuer_url" {
  description = "URL of the EKS OIDC issuer"
  type        = string
}

variable "app_namespace" {
  description = "Kubernetes namespace where application services are deployed"
  type        = string
  default     = "martianbank"
}

variable "github_org" {
  description = "GitHub organization name for OIDC trust policy (Requirement 9.4)"
  type        = string
  default     = ""
}

variable "github_repo" {
  description = "GitHub repository name for OIDC trust policy (Requirement 9.4)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
