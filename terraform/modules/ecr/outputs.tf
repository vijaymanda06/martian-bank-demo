# ECR Module Outputs

output "repository_urls" {
  description = "Map of service names to their ECR repository URLs"
  value = {
    for name, repo in aws_ecr_repository.services : name => repo.repository_url
  }
}

output "repository_arns" {
  description = "Map of service names to their ECR repository ARNs"
  value = {
    for name, repo in aws_ecr_repository.services : name => repo.arn
  }
}

output "repository_names" {
  description = "Map of service names to their full ECR repository names"
  value = {
    for name, repo in aws_ecr_repository.services : name => repo.name
  }
}

output "registry_id" {
  description = "The registry ID where the repositories are created"
  value       = values(aws_ecr_repository.services)[0].registry_id
}

# Individual repository URLs for convenience
output "accounts_repository_url" {
  description = "ECR repository URL for accounts service"
  value       = aws_ecr_repository.services["accounts"].repository_url
}

output "loan_repository_url" {
  description = "ECR repository URL for loan service"
  value       = aws_ecr_repository.services["loan"].repository_url
}

output "transactions_repository_url" {
  description = "ECR repository URL for transactions service"
  value       = aws_ecr_repository.services["transactions"].repository_url
}

output "dashboard_repository_url" {
  description = "ECR repository URL for dashboard service"
  value       = aws_ecr_repository.services["dashboard"].repository_url
}

output "customer_auth_repository_url" {
  description = "ECR repository URL for customer-auth service"
  value       = aws_ecr_repository.services["customer-auth"].repository_url
}

output "atm_locator_repository_url" {
  description = "ECR repository URL for atm-locator service"
  value       = aws_ecr_repository.services["atm-locator"].repository_url
}

output "ui_repository_url" {
  description = "ECR repository URL for UI"
  value       = aws_ecr_repository.services["ui"].repository_url
}
