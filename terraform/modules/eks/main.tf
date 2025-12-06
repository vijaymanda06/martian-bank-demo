# EKS Module - Creates Kubernetes cluster with Auto Mode
#
# Uses terraform-aws-modules/eks/aws v20.x for EKS Auto Mode support
# Auto Mode enables AWS-managed node pools, Karpenter scaling, and ALB controller
#
# Requirements: 5.1, 5.2, 6.1

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # EKS Auto Mode configuration (Requirement 5.1, 5.2)
  # AWS manages node pools, scaling (via Karpenter), and load balancing automatically
  # When enabled, AWS provisions and manages compute resources for the cluster
  cluster_compute_config = {
    enabled    = true
    node_pools = var.auto_mode_node_pools
  }

  # Enable OIDC provider for IRSA (Requirement 6.1)
  # This creates an OpenID Connect provider for the cluster
  # allowing pods to assume IAM roles via service account annotations
  enable_irsa = true

  # Cluster endpoint access configuration
  # Public access allows kubectl from outside VPC (controlled by CIDR)
  # Private access allows nodes and pods to communicate with API server
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  # Enable cluster creator admin permissions
  # Grants the IAM principal creating the cluster admin access
  enable_cluster_creator_admin_permissions = true

  # Additional access entries for cluster administration
  access_entries = var.access_entries

  # Cluster security group configuration
  # Additional rules can be added via variables
  cluster_security_group_additional_rules = var.cluster_security_group_additional_rules

  # Node security group configuration for Auto Mode managed nodes
  node_security_group_additional_rules = var.node_security_group_additional_rules

  # Cluster addons - core networking and DNS components
  # In Auto Mode, these are still required for cluster functionality
  cluster_addons = {
    coredns = {
      most_recent = true
      configuration_values = jsonencode({
        tolerations = [
          {
            key      = "eks.amazonaws.com/compute-type"
            operator = "Equal"
            value    = "auto"
            effect   = "NoSchedule"
          }
        ]
      })
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
      configuration_values = jsonencode({
        enableNetworkPolicy = tostring(var.enable_network_policy)
      })
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
  }

  # CloudWatch logging for cluster components
  cluster_enabled_log_types = var.cluster_enabled_log_types

  tags = var.tags
}
