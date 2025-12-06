# Root Module - Orchestrates all infrastructure modules
#
# This is the main entry point for the Martian Bank infrastructure.
# It calls child modules for VPC, EKS, IAM, and Secrets.

locals {
  cluster_name = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# VPC Module - Creates networking infrastructure
module "vpc" {
  source = "./modules/vpc"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  cluster_name       = local.cluster_name

  tags = local.common_tags
}

# EKS Module - Creates Kubernetes cluster with Auto Mode
# Requirements: 5.1, 5.2, 6.1
module "eks" {
  source = "./modules/eks"

  cluster_name                         = local.cluster_name
  cluster_version                      = var.cluster_version
  vpc_id                               = module.vpc.vpc_id
  subnet_ids                           = module.vpc.private_subnet_ids
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  auto_mode_node_pools                 = var.auto_mode_node_pools
  enable_network_policy                = var.enable_network_policy
  cluster_enabled_log_types            = var.cluster_enabled_log_types

  tags = local.common_tags
}

# IAM Module - Creates roles and policies
module "iam" {
  source = "./modules/iam"

  project_name          = var.project_name
  environment           = var.environment
  eks_cluster_name      = module.eks.cluster_name
  eks_oidc_provider_arn = module.eks.oidc_provider_arn
  eks_oidc_issuer_url   = module.eks.oidc_issuer_url
  github_org            = var.github_org
  github_repo           = var.github_repo

  tags = local.common_tags
}

# Secrets Module - Creates AWS Secrets Manager resources
module "secrets" {
  source = "./modules/secrets"

  project_name = var.project_name
  environment  = var.environment
  mongodb_uri  = var.mongodb_uri
  jwt_secret   = var.jwt_secret

  tags = local.common_tags
}

# ECR Module - Creates container image repositories
# Requirements: 8.4
module "ecr" {
  source = "./modules/ecr"

  project_name               = var.project_name
  environment                = var.environment
  image_tag_mutability       = var.ecr_image_tag_mutability
  scan_on_push               = var.ecr_scan_on_push
  max_image_count            = var.ecr_max_image_count
  max_dev_image_count        = var.ecr_max_dev_image_count
  untagged_image_expiry_days = var.ecr_untagged_image_expiry_days
  sha_image_expiry_days      = var.ecr_sha_image_expiry_days

  tags = local.common_tags
}
