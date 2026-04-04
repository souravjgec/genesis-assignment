variable "function_name" {
  description = "Name of the Lambda function."
  type        = string
}

variable "lambda_role_arn" {
  description = "Execution role ARN for the Lambda function."
  type        = string
}

variable "runtime" {
  description = "Lambda runtime identifier."
  type        = string
  default     = "python3.12"
}

variable "timeout_seconds" {
  description = "Lambda timeout in seconds."
  type        = number
  default     = 10
}

variable "memory_size_mb" {
  description = "Lambda memory size in MB."
  type        = number
  default     = 256
}

variable "architecture" {
  description = "Lambda CPU architecture."
  type        = string
  default     = "x86_64"
}

variable "config_parameter_name" {
  description = "Name of the SSM parameter the application can read at runtime."
  type        = string
}

variable "secret_arn" {
  description = "Secrets Manager secret ARN the application can read at runtime."
  type        = string
}

variable "custom_metric_namespace" {
  description = "CloudWatch metric namespace used by the application."
  type        = string
}

variable "custom_metric_name" {
  description = "CloudWatch custom metric name emitted by the application."
  type        = string
}

variable "tags" {
  description = "Tags applied to the Lambda function."
  type        = map(string)
}
