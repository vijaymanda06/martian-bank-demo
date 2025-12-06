# Secrets Module - Creates AWS Secrets Manager resources
#
# Creates:
# - MongoDB credentials secret
# - JWT configuration secret
# - Optional rotation configuration

# MongoDB Credentials Secret
resource "aws_secretsmanager_secret" "mongodb" {
  name        = "${var.project_name}/${var.environment}/mongodb"
  description = "MongoDB connection credentials for ${var.project_name}"

  # Recovery window for deletion (minimum 7 days, 0 for immediate)
  recovery_window_in_days = var.recovery_window_in_days

  tags = var.tags
}

# SECURITY NOTE: Default values below are for LOCAL/DEV use only!
# For production deployments, ALWAYS override these values via:
#   - terraform.tfvars
#   - Environment-specific .tfvars files (e.g., prod.tfvars)
#   - CI/CD pipeline variables
# Never deploy to production with default/empty credentials!
resource "aws_secretsmanager_secret_version" "mongodb" {
  secret_id = aws_secretsmanager_secret.mongodb.id
  secret_string = jsonencode({
    uri      = var.mongodb_uri != "" ? var.mongodb_uri : "mongodb://localhost:27017"
    database = var.mongodb_database
    username = var.mongodb_username
    password = var.mongodb_password
  })
}

# Optional: MongoDB secret rotation schedule
resource "aws_secretsmanager_secret_rotation" "mongodb" {
  count = var.enable_secret_rotation ? 1 : 0

  secret_id           = aws_secretsmanager_secret.mongodb.id
  rotation_lambda_arn = var.rotation_lambda_arn

  rotation_rules {
    automatically_after_days = var.rotation_days
  }
}

# JWT Configuration Secret
resource "aws_secretsmanager_secret" "jwt" {
  name        = "${var.project_name}/${var.environment}/jwt"
  description = "JWT configuration for ${var.project_name}"

  # Recovery window for deletion
  recovery_window_in_days = var.recovery_window_in_days

  tags = var.tags
}

# SECURITY NOTE: Default JWT secret is for LOCAL/DEV use only!
# For production, ALWAYS provide a strong, randomly generated secret via:
#   - terraform.tfvars (not committed to git)
#   - Environment variables: TF_VAR_jwt_secret
#   - CI/CD pipeline secrets
# The default "change-me-in-production" value will cause authentication issues if deployed!
resource "aws_secretsmanager_secret_version" "jwt" {
  secret_id = aws_secretsmanager_secret.jwt.id
  secret_string = jsonencode({
    secret = var.jwt_secret != "" ? var.jwt_secret : "change-me-in-production"
    expiry = var.jwt_expiry
  })
}

# Optional: JWT secret rotation schedule
resource "aws_secretsmanager_secret_rotation" "jwt" {
  count = var.enable_secret_rotation ? 1 : 0

  secret_id           = aws_secretsmanager_secret.jwt.id
  rotation_lambda_arn = var.rotation_lambda_arn

  rotation_rules {
    automatically_after_days = var.rotation_days
  }
}

# IAM Policy for External Secrets Operator to read secrets
data "aws_iam_policy_document" "eso_secrets_access" {
  statement {
    sid    = "AllowSecretsManagerRead"
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]

    resources = [
      aws_secretsmanager_secret.mongodb.arn,
      aws_secretsmanager_secret.jwt.arn,
    ]
  }
}

resource "aws_iam_policy" "eso_secrets_access" {
  name        = "${var.project_name}-${var.environment}-eso-secrets-access"
  description = "Policy for External Secrets Operator to access Secrets Manager"
  policy      = data.aws_iam_policy_document.eso_secrets_access.json

  tags = var.tags
}
