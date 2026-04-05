data "archive_file" "bootstrap" {
  type        = "zip"
  source_file = "${path.module}/../../../app/main.py"
  output_path = "${path.module}/build/bootstrap.zip"
}

locals {
  signer_profile_prefix = substr(join("", regexall("[0-9A-Za-z]+", var.function_name)), 0, 38)
}

#checkov:skip=CKV_AWS_117: The Lambda stays outside a VPC because it has no private resource dependency and the assignment favors low-cost simplicity.
#checkov:skip=CKV_AWS_115: Reserved concurrency is intentionally unset because this AWS account cannot reserve concurrency without violating the minimum unreserved concurrency requirement.
#checkov:skip=CKV_AWS_272: Code signing is intentionally disabled because the deployment pipeline uploads a standard unsigned zip with aws lambda update-function-code.
resource "aws_sqs_queue" "lambda_dlq" {
  name                       = "${var.function_name}-dlq"
  sqs_managed_sse_enabled    = true
  message_retention_seconds  = 1209600
  visibility_timeout_seconds = 30

  tags = var.tags
}

data "aws_iam_policy_document" "lambda_dlq" {
  statement {
    sid = "AllowSendingMessagesToDlq"
    actions = [
      "sqs:SendMessage",
    ]
    resources = [aws_sqs_queue.lambda_dlq.arn]
  }
}

resource "aws_iam_role_policy" "lambda_dlq" {
  name   = "${var.function_name}-dlq"
  role   = var.lambda_role_name
  policy = data.aws_iam_policy_document.lambda_dlq.json
}

# Retained so Terraform does not try to delete these AWS resources while Lambda is still settling.
resource "aws_signer_signing_profile" "lambda" {
  name_prefix = local.signer_profile_prefix
  platform_id = "AWSLambda-SHA384-ECDSA"

  signature_validity_period {
    value = 12
    type  = "MONTHS"
  }

  tags = var.tags
}

# Intentionally kept detached from the function to avoid immediate destroy conflicts in AWS Lambda.
resource "aws_lambda_code_signing_config" "this" {
  allowed_publishers {
    signing_profile_version_arns = [
      aws_signer_signing_profile.lambda.version_arn,
    ]
  }

  policies {
    untrusted_artifact_on_deployment = "Enforce"
  }
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
  kms_key_arn      = var.kms_key_arn

  environment {
    variables = {
      CONFIG_PARAMETER_NAME = var.config_parameter_name
      ITEMS_METRIC_NS       = var.custom_metric_namespace
      ITEMS_METRIC_NAME     = var.custom_metric_name
      LOG_LEVEL             = "INFO"
    }
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }

  tracing_config {
    mode = "Active"
  }

  tags = var.tags
}

#checkov:skip=CKV_AWS_258: Function URL auth remains NONE so the existing public endpoint behavior is preserved.
resource "aws_lambda_function_url" "this" {
  function_name      = aws_lambda_function.this.function_name
  authorization_type = "NONE"
}

#checkov:skip=CKV_AWS_301: Public invoke permission is preserved because the function URL is intentionally public.
resource "aws_lambda_permission" "function_url" {
  statement_id           = "AllowFunctionUrlInvoke"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.this.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}

resource "aws_lambda_permission" "function_url_invoke" {
  statement_id             = "AllowFunctionInvokeFromFunctionUrl"
  action                   = "lambda:InvokeFunction"
  function_name            = aws_lambda_function.this.function_name
  principal                = "*"
  invoked_via_function_url = true
}
