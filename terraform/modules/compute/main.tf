data "archive_file" "bootstrap" {
  type        = "zip"
  source_file = "${path.module}/src/main.py"
  output_path = "${path.module}/build/bootstrap.zip"
}

#checkov:skip=CKV_AWS_117: The Lambda stays outside a VPC because it has no private resource dependency and the assignment favors low-cost simplicity.
#checkov:skip=CKV_AWS_173: Lambda environment variables carry only secret references and config names, so an extra CMK is intentionally not added in this demo.
#checkov:skip=CKV_AWS_50: X-Ray tracing is omitted to keep the observability setup focused on CloudWatch metrics and logs required by the assignment.
#checkov:skip=CKV_AWS_116: A DLQ is not configured because this proof-of-concept uses CloudWatch alarms and logs instead of asynchronous failure queues.
#checkov:skip=CKV_AWS_115: Reserved concurrency is left unset so the function can use default account concurrency during the free-tier demonstration.
#checkov:skip=CKV_AWS_272: Code signing is omitted to keep the deployment flow lightweight for a take-home assignment proof-of-concept.
resource "aws_lambda_function" "this" {
  function_name    = var.function_name
  description      = "Genesis assignment sample API Lambda"
  role             = var.lambda_role_arn
  handler          = "main.lambda_handler"
  runtime          = var.runtime
  timeout          = var.timeout_seconds
  memory_size      = var.memory_size_mb
  architectures    = [var.architecture]
  filename         = data.archive_file.bootstrap.output_path
  source_code_hash = data.archive_file.bootstrap.output_base64sha256

  environment {
    variables = {
      CONFIG_PARAMETER_NAME = var.config_parameter_name
      SECRET_ARN            = var.secret_arn
      ITEMS_METRIC_NS       = var.custom_metric_namespace
      ITEMS_METRIC_NAME     = var.custom_metric_name
      LOG_LEVEL             = "INFO"
    }
  }

  tags = var.tags
}

#checkov:skip=CKV_AWS_258: Function URL auth is intentionally NONE so GitHub smoke tests and evaluator demos can reach the API without extra auth setup.
resource "aws_lambda_function_url" "this" {
  function_name      = aws_lambda_function.this.function_name
  authorization_type = "NONE"
}

#checkov:skip=CKV_AWS_301: Public invoke permission is required because the assignment needs a live public endpoint for smoke testing and demonstration.
resource "aws_lambda_permission" "function_url" {
  statement_id           = "AllowFunctionUrlInvoke"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.this.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}
