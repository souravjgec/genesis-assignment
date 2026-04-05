output "terraform_state_bucket_name" {
  description = "Name of the S3 bucket intended for Terraform remote state."
  value       = aws_s3_bucket.terraform_state.bucket
}

output "terraform_lock_table_name" {
  description = "Name of the DynamoDB table intended for Terraform state locking."
  value       = aws_dynamodb_table.terraform_lock.name
}

output "lambda_function_name" {
  description = "Name of the provisioned Lambda function."
  value       = module.compute.lambda_function_name
}

output "lambda_function_arn" {
  description = "ARN of the provisioned Lambda function."
  value       = module.compute.lambda_function_arn
}

output "api_base_url" {
  description = "IAM-authenticated base URL for the deployed API."
  value       = module.compute.lambda_function_url
}

output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions OIDC deploy role."
  value       = module.iam.github_actions_role_arn
}

output "cloudwatch_dashboard_name" {
  description = "CloudWatch dashboard created for the Lambda service."
  value       = module.observability.dashboard_name
}

output "high_error_rate_alarm_name" {
  description = "CloudWatch alarm name for the high error rate alert."
  value       = module.observability.alarm_name
}

output "alert_sns_topic_arn" {
  description = "SNS topic ARN used for error rate notifications."
  value       = module.observability.sns_topic_arn
}
