variable "aws_region" {
  description = "AWS region for the deployment."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used in resource naming."
  type        = string
  default     = "genesis-items-api"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Resource owner tag value."
  type        = string
}

variable "function_name" {
  description = "Lambda function name."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository in owner/name format."
  type        = string
}

variable "github_main_branch" {
  description = "Primary branch name allowed to deploy."
  type        = string
  default     = "main"
}

variable "alarm_email" {
  description = "Email address subscribed to the SNS alert topic."
  type        = string
}

variable "runbook_url" {
  description = "Runbook URL included in the CloudWatch alarm."
  type        = string
  default     = ""
}
