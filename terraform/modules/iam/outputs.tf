# IAM Module Outputs
#
# Requirements: 6.2, 6.3, 6.4, 9.3, 9.4

#------------------------------------------------------------------------------
# GitHub Actions Outputs (Requirements: 9.3, 9.4)
#------------------------------------------------------------------------------

output "github_actions_role_arn" {
  description = "ARN of the IAM role for GitHub Actions"
  value       = length(aws_iam_role.github_actions) > 0 ? aws_iam_role.github_actions[0].arn : ""
}

output "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = length(aws_iam_openid_connect_provider.github) > 0 ? aws_iam_openid_connect_provider.github[0].arn : ""
}

#------------------------------------------------------------------------------
# External Secrets Operator Outputs (Requirement: 6.2)
#------------------------------------------------------------------------------

output "external_secrets_role_arn" {
  description = "ARN of the IAM role for External Secrets Operator"
  value       = aws_iam_role.external_secrets.arn
}

#------------------------------------------------------------------------------
# Service Account IRSA Role Outputs (Requirements: 6.2, 6.3)
#------------------------------------------------------------------------------

output "service_account_role_arns" {
  description = "Map of service account names to their IAM role ARNs for IRSA"
  value       = { for k, v in aws_iam_role.service_account : k => v.arn }
}

output "accounts_role_arn" {
  description = "ARN of the IAM role for accounts service"
  value       = aws_iam_role.service_account["accounts"].arn
}

output "loan_role_arn" {
  description = "ARN of the IAM role for loan service"
  value       = aws_iam_role.service_account["loan"].arn
}

output "transactions_role_arn" {
  description = "ARN of the IAM role for transactions service"
  value       = aws_iam_role.service_account["transactions"].arn
}

output "dashboard_role_arn" {
  description = "ARN of the IAM role for dashboard service"
  value       = aws_iam_role.service_account["dashboard"].arn
}

output "customer_auth_role_arn" {
  description = "ARN of the IAM role for customer-auth service"
  value       = aws_iam_role.service_account["customer-auth"].arn
}

output "atm_locator_role_arn" {
  description = "ARN of the IAM role for atm-locator service"
  value       = aws_iam_role.service_account["atm-locator"].arn
}
