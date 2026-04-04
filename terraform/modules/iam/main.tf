data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

locals {
  oidc_provider_host = "token.actions.githubusercontent.com"
  allowed_subjects = [
    "repo:${var.github_repository}:ref:refs/heads/${var.github_main_branch}",
    "repo:${var.github_repository}:environment:${var.github_environment}",
  ]
}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://${local.oidc_provider_host}"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
  ]

  tags = var.tags
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    sid     = "AllowLambdaServiceAssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_execution" {
  name               = "${var.name_prefix}-lambda-execution"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = var.tags
}

data "aws_iam_policy_document" "lambda_permissions" {
  statement {
    sid = "AllowWritingFunctionLogs"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "${var.log_group_arn}:*",
    ]
  }

  statement {
    sid = "AllowPublishingCustomMetrics"
    actions = [
      "cloudwatch:PutMetricData",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "cloudwatch:namespace"
      values   = [var.custom_metric_namespace]
    }
  }

  statement {
    sid = "AllowReadingConfigParameter"
    actions = [
      "ssm:GetParameter",
    ]
    resources = [var.config_parameter_arn]
  }

  statement {
    sid = "AllowReadingSecret"
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = [var.secret_arn]
  }
}

resource "aws_iam_role_policy" "lambda_permissions" {
  name   = "${var.name_prefix}-lambda-permissions"
  role   = aws_iam_role.lambda_execution.id
  policy = data.aws_iam_policy_document.lambda_permissions.json
}

locals {
  lambda_function_arn = "arn:${data.aws_partition.current.partition}:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:${var.lambda_function_name}"
}

data "aws_iam_policy_document" "github_oidc_assume_role" {
  statement {
    sid     = "AllowGitHubActionsOidc"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_host}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "${local.oidc_provider_host}:sub"
      values   = local.allowed_subjects
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "${var.name_prefix}-github-actions"
  assume_role_policy = data.aws_iam_policy_document.github_oidc_assume_role.json
  tags               = var.tags
}

data "aws_iam_policy_document" "github_actions_permissions" {
  statement {
    sid = "AllowDeployingLambdaCode"
    actions = [
      "lambda:GetFunction",
      "lambda:GetFunctionConfiguration",
      "lambda:UpdateFunctionCode",
    ]
    resources = [local.lambda_function_arn]
  }
}

resource "aws_iam_role_policy" "github_actions_permissions" {
  name   = "${var.name_prefix}-github-actions-deploy"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_actions_permissions.json
}
