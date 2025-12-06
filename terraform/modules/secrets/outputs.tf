# Secrets Module Outputs

output "mongodb_secret_arn" {
  description = "ARN of the MongoDB credentials secret"
  value       = aws_secretsmanager_secret.mongodb.arn
}

output "mongodb_secret_name" {
  description = "Name of the MongoDB credentials secret"
  value       = aws_secretsmanager_secret.mongodb.name
}

output "jwt_secret_arn" {
  description = "ARN of the JWT configuration secret"
  value       = aws_secretsmanager_secret.jwt.arn
}

output "jwt_secret_name" {
  description = "Name of the JWT configuration secret"
  value       = aws_secretsmanager_secret.jwt.name
}

output "eso_secrets_access_policy_arn" {
  description = "ARN of the IAM policy for External Secrets Operator"
  value       = aws_iam_policy.eso_secrets_access.arn
}

output "secret_arns" {
  description = "List of all secret ARNs managed by this module"
  value = [
    aws_secretsmanager_secret.mongodb.arn,
    aws_secretsmanager_secret.jwt.arn,
  ]
}
