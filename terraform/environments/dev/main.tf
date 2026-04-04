locals {
  name_prefix = var.function_name
  owner_tag   = trimspace(replace(replace(var.owner, "<", ""), ">", ""))
  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
    Owner       = local.owner_tag
  }
  config_parameter_name   = "/genesis/${var.environment}/app-config"
  secret_name             = "genesis/${var.environment}/app-secret"
  lambda_runtime          = "python3.12"
  lambda_timeout_seconds  = 10
  lambda_memory_size_mb   = 256
  custom_metric_namespace = "Genesis/ItemsApi"
  custom_metric_name      = "ItemsCreated"
  log_retention_days      = 14
  runbook_url             = var.runbook_url != "" ? var.runbook_url : "https://github.com/${var.github_repo}/blob/main/docs/runbooks/high-error-rate.md"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "${local.name_prefix}-tf-state"
  tags   = local.tags
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_lock" {
  name         = "${local.name_prefix}-tf-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = local.tags
}

resource "aws_ssm_parameter" "app_config" {
  name  = local.config_parameter_name
  type  = "String"
  value = "{\"environment\":\"${var.environment}\"}"
  tags  = local.tags
}

resource "aws_secretsmanager_secret" "app_secret" {
  name = local.secret_name
  tags = local.tags
}

module "observability" {
  source = "../../modules/observability"

  name_prefix             = local.name_prefix
  lambda_function_name    = local.name_prefix
  aws_region              = var.aws_region
  alert_email             = var.alarm_email
  runbook_url             = local.runbook_url
  log_retention_days      = local.log_retention_days
  custom_metric_namespace = local.custom_metric_namespace
  custom_metric_name      = local.custom_metric_name
  tags                    = local.tags
}

module "iam" {
  source = "../../modules/iam"

  name_prefix             = local.name_prefix
  github_repository       = var.github_repo
  github_main_branch      = var.github_main_branch
  lambda_function_name    = local.name_prefix
  aws_region              = var.aws_region
  log_group_arn           = module.observability.log_group_arn
  custom_metric_namespace = local.custom_metric_namespace
  config_parameter_arn    = aws_ssm_parameter.app_config.arn
  secret_arn              = aws_secretsmanager_secret.app_secret.arn
  tags                    = local.tags
}

module "compute" {
  source = "../../modules/compute"

  function_name           = local.name_prefix
  lambda_role_arn         = module.iam.lambda_execution_role_arn
  runtime                 = local.lambda_runtime
  timeout_seconds         = local.lambda_timeout_seconds
  memory_size_mb          = local.lambda_memory_size_mb
  config_parameter_name   = aws_ssm_parameter.app_config.name
  secret_arn              = aws_secretsmanager_secret.app_secret.arn
  custom_metric_namespace = local.custom_metric_namespace
  custom_metric_name      = local.custom_metric_name
  tags                    = local.tags
}
