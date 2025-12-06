# ECR Module - Creates AWS Elastic Container Registry repositories
#
# Creates:
# - ECR repository for each Martian Bank service
# - Image scanning on push configuration
# - Lifecycle policies for image cleanup
#
# Requirements: 8.4

locals {
  # List of all services that need ECR repositories
  services = [
    "accounts",
    "loan",
    "transactions",
    "dashboard",
    "customer-auth",
    "atm-locator",
    "ui"
  ]
}

# ECR Repository for each service
resource "aws_ecr_repository" "services" {
  for_each = toset(local.services)

  name                 = "${var.project_name}/${each.key}"
  image_tag_mutability = var.image_tag_mutability

  # Enable image scanning on push
  # Requirements: 8.4 - Configure image scanning on push
  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  # Enable encryption
  encryption_configuration {
    encryption_type = var.encryption_type
    kms_key         = var.encryption_type == "KMS" ? var.kms_key_arn : null
  }

  tags = merge(var.tags, {
    Service = each.key
  })
}

# Lifecycle policy for image cleanup
# Requirements: 8.4 - Set lifecycle policies for image cleanup
resource "aws_ecr_lifecycle_policy" "services" {
  for_each = aws_ecr_repository.services

  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.max_image_count} images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "release"]
          countType     = "imageCountMoreThan"
          countNumber   = var.max_image_count
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Expire untagged images older than ${var.untagged_image_expiry_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.untagged_image_expiry_days
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 3
        description  = "Keep last ${var.max_dev_image_count} dev/feature images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["dev", "feature", "pr"]
          countType     = "imageCountMoreThan"
          countNumber   = var.max_dev_image_count
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 4
        description  = "Expire SHA-tagged images older than ${var.sha_image_expiry_days} days"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["sha-"]
          countType     = "sinceImagePushed"
          countUnit     = "days"
          countNumber   = var.sha_image_expiry_days
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Repository policy for cross-account access (optional)
resource "aws_ecr_repository_policy" "services" {
  for_each = var.enable_cross_account_access ? aws_ecr_repository.services : {}

  repository = each.value.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCrossAccountPull"
        Effect = "Allow"
        Principal = {
          AWS = var.cross_account_arns
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      }
    ]
  })
}
