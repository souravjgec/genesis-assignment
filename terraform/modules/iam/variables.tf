variable "name_prefix" {
  description = "Prefix used for IAM resource names."
  type        = string
}

variable "github_repository" {
  description = "GitHub repository in owner/name format allowed to assume the deploy role."
  type        = string
}

variable "github_main_branch" {
  description = "Branch name allowed to deploy through GitHub Actions OIDC."
  type        = string
  default     = "main"
}

variable "github_environment" {
  description = "GitHub Actions environment name allowed to assume the deploy role."
  type        = string
  default     = "dev"
}

variable "lambda_function_name" {
  description = "Name of the Lambda function that GitHub Actions is allowed to update."
  type        = string
}

variable "aws_region" {
  description = "AWS region where the Lambda function is deployed."
  type        = string
}

variable "log_group_arn" {
  description = "ARN of the CloudWatch Log Group used by the Lambda function."
  type        = string
}

variable "custom_metric_namespace" {
  description = "CloudWatch namespace used by the application for custom metrics."
  type        = string
}

variable "config_parameter_arn" {
  description = "ARN of the SSM parameter the Lambda function can read."
  type        = string
}

variable "secret_arn" {
  description = "ARN of the Secrets Manager secret the Lambda function can read."
  type        = string
}

variable "tags" {
  description = "Tags applied to IAM resources."
  type        = map(string)
}
