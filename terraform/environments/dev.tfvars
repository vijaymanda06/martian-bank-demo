# Development Environment Configuration

aws_region   = "us-west-1"
project_name = "martianbank"
environment  = "dev"

# VPC Configuration
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-west-1a", "us-west-1b"]

# EKS Configuration
cluster_version                      = "1.31"
cluster_endpoint_public_access       = true
cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]
auto_mode_node_pools                 = ["general-purpose", "system"]
enable_network_policy                = true
cluster_enabled_log_types            = ["api", "audit", "authenticator"]

# GitHub OIDC Configuration
# Update these values with your GitHub organization and repository
github_org  = ""
github_repo = ""

# Secrets Configuration
# These should be provided via environment variables or a secrets file
# TF_VAR_mongodb_uri="mongodb://..."
# TF_VAR_jwt_secret="..."
