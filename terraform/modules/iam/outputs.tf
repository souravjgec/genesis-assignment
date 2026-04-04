output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution role."
  value       = aws_iam_role.lambda_execution.arn
}

output "lambda_execution_role_name" {
  description = "Name of the Lambda execution role."
  value       = aws_iam_role.lambda_execution.name
}

output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions deploy role."
  value       = aws_iam_role.github_actions.arn
}

output "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider."
  value       = aws_iam_openid_connect_provider.github.arn
}
