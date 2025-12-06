# EKS Module Outputs
#
# Outputs for EKS cluster with Auto Mode
# These outputs are used by other modules (IAM, Secrets) for IRSA configuration
# Requirements: 5.1, 5.2, 6.1

# Cluster Identity
output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = module.eks.cluster_arn
}

output "cluster_id" {
  description = "ID of the EKS cluster (same as cluster_name for EKS)"
  value       = module.eks.cluster_id
}

# Cluster Access
output "cluster_endpoint" {
  description = "Endpoint for the EKS cluster API server"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for cluster authentication"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_version" {
  description = "Kubernetes version of the cluster"
  value       = module.eks.cluster_version
}

# OIDC Provider for IRSA (Requirement 6.1)
output "oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA"
  value       = module.eks.oidc_provider_arn
}

output "oidc_issuer_url" {
  description = "URL of the OIDC issuer (with https:// prefix)"
  value       = module.eks.cluster_oidc_issuer_url
}

output "oidc_provider" {
  description = "OIDC provider URL without https:// prefix (for IAM trust policies)"
  value       = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
}

# Security Groups
output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster control plane"
  value       = module.eks.cluster_security_group_id
}

output "node_security_group_id" {
  description = "Security group ID attached to the EKS nodes"
  value       = module.eks.node_security_group_id
}

output "cluster_primary_security_group_id" {
  description = "Primary security group ID of the cluster (created by EKS)"
  value       = module.eks.cluster_primary_security_group_id
}

# Cluster Addons
output "cluster_addons" {
  description = "Map of cluster addon attributes"
  value       = module.eks.cluster_addons
}

# Platform Version
output "cluster_platform_version" {
  description = "Platform version of the EKS cluster"
  value       = module.eks.cluster_platform_version
}

# Status
output "cluster_status" {
  description = "Status of the EKS cluster"
  value       = module.eks.cluster_status
}
