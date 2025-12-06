# IAM Module - Creates roles and policies for EKS and GitHub Actions
#
# Creates:
# - GitHub OIDC provider for Actions authentication
# - IAM role for GitHub Actions with ECR and EKS permissions
# - IAM role for External Secrets Operator (IRSA)
# - Service account IAM roles for IRSA (accounts, loan, transactions, dashboard)
#
# Requirements: 6.2, 6.3, 6.4, 9.3, 9.4

locals {
  oidc_issuer = replace(var.eks_oidc_issuer_url, "https://", "")

  # Service accounts that need IRSA roles
  # Each service gets a role with least-privilege permissions
  service_accounts = {
    accounts = {
      namespace = var.app_namespace
      name      = "accounts"
    }
    loan = {
      namespace = var.app_namespace
      name      = "loan"
    }
    transactions = {
      namespace = var.app_namespace
      name      = "transactions"
    }
    dashboard = {
      namespace = var.app_namespace
      name      = "dashboard"
    }
    customer-auth = {
      namespace = var.app_namespace
      name      = "customer-auth"
    }
    atm-locator = {
      namespace = var.app_namespace
      name      = "atm-locator"
    }
  }
}

#------------------------------------------------------------------------------
# GitHub OIDC Provider and Role (Requirements: 9.3, 9.4)
#------------------------------------------------------------------------------

# GitHub OIDC Provider
# Creates the identity provider that allows GitHub Actions to authenticate
resource "aws_iam_openid_connect_provider" "github" {
  count = var.github_org != "" ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]

  tags = var.tags
}

# IAM Role for GitHub Actions
# Trust policy restricts access to specific repository only (Requirement 9.4)
resource "aws_iam_role" "github_actions" {
  count = var.github_org != "" ? 1 : 0

  name = "${var.project_name}-${var.environment}-github-actions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github[0].arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
        }
      }
    }]
  })

  tags = var.tags
}

# ECR Policy for GitHub Actions
# Allows pushing images to ECR repositories (least-privilege)
resource "aws_iam_role_policy" "github_actions_ecr" {
  count = var.github_org != "" ? 1 : 0

  name = "ecr-push-policy"
  role = aws_iam_role.github_actions[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = "arn:aws:ecr:*:*:repository/${var.project_name}-*"
      }
    ]
  })
}

# EKS Policy for GitHub Actions
# Allows describing cluster for kubectl configuration
resource "aws_iam_role_policy" "github_actions_eks" {
  count = var.github_org != "" ? 1 : 0

  name = "eks-deploy-policy"
  role = aws_iam_role.github_actions[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = "*"
      }
    ]
  })
}

#------------------------------------------------------------------------------
# External Secrets Operator IRSA Role (Requirement 6.2, 6.3)
#------------------------------------------------------------------------------

# External Secrets Operator IRSA Role
# Uses web identity token federation for secure authentication (Requirement 6.3)
resource "aws_iam_role" "external_secrets" {
  name = "${var.project_name}-${var.environment}-external-secrets"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.eks_oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_issuer}:aud" = "sts.amazonaws.com"
          "${local.oidc_issuer}:sub" = "system:serviceaccount:external-secrets:external-secrets"
        }
      }
    }]
  })

  tags = var.tags
}

# Secrets Manager Policy for External Secrets Operator
# Least-privilege: only read secrets under project prefix (Requirement 6.4)
resource "aws_iam_role_policy" "external_secrets_sm" {
  name = "secrets-manager-read-policy"
  role = aws_iam_role.external_secrets.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:*:*:secret:${var.project_name}/*"
      }
    ]
  })
}

#------------------------------------------------------------------------------
# Service Account IRSA Roles (Requirements: 6.2, 6.3, 6.4)
#------------------------------------------------------------------------------

# IRSA roles for application services
# Each service gets its own role with least-privilege permissions
# Uses web identity token federation (Requirement 6.3)
resource "aws_iam_role" "service_account" {
  for_each = local.service_accounts

  name = "${var.project_name}-${var.environment}-${each.key}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.eks_oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_issuer}:aud" = "sts.amazonaws.com"
          "${local.oidc_issuer}:sub" = "system:serviceaccount:${each.value.namespace}:${each.value.name}"
        }
      }
    }]
  })

  tags = merge(var.tags, {
    ServiceAccount = each.value.name
    Namespace      = each.value.namespace
  })
}

# Secrets Manager read policy for service accounts
# Least-privilege: services can only read their own secrets (Requirement 6.4)
resource "aws_iam_role_policy" "service_account_secrets" {
  for_each = local.service_accounts

  name = "secrets-read-policy"
  role = aws_iam_role.service_account[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          "arn:aws:secretsmanager:*:*:secret:${var.project_name}/${each.key}/*",
          "arn:aws:secretsmanager:*:*:secret:${var.project_name}/shared/*"
        ]
      }
    ]
  })
}
