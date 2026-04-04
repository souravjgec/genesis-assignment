data "archive_file" "bootstrap" {
  type        = "zip"
  source_file = "${path.module}/src/main.py"
  output_path = "${path.module}/build/bootstrap.zip"
}

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

resource "aws_lambda_function_url" "this" {
  function_name      = aws_lambda_function.this.function_name
  authorization_type = "NONE"
}

resource "aws_lambda_permission" "function_url" {
  statement_id           = "AllowFunctionUrlInvoke"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.this.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}
