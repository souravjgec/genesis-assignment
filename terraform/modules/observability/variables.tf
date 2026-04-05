variable "name_prefix" {
  description = "Prefix used for observability resources."
  type        = string
}

variable "lambda_function_name" {
  description = "Name of the Lambda function being monitored."
  type        = string
}

variable "aws_region" {
  description = "AWS region for dashboard widgets."
  type        = string
}

variable "alert_email" {
  description = "Email endpoint subscribed to the SNS alert topic."
  type        = string
}

variable "runbook_url" {
  description = "Runbook URL referenced in the alarm description."
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch Log Group retention in days."
  type        = number
  default     = 14
}

variable "custom_metric_namespace" {
  description = "CloudWatch namespace for application custom metrics."
  type        = string
}

variable "custom_metric_name" {
  description = "CloudWatch custom metric name for created items."
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN used for CloudWatch Logs and SNS encryption."
  type        = string
}

variable "tags" {
  description = "Tags applied to observability resources."
  type        = map(string)
}
