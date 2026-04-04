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

#checkov:skip=CKV_AWS_144: Cross-region replication is intentionally omitted for this single-region assignment backend to stay within free-tier limits.
#checkov:skip=CKV2_AWS_62: Event notifications are not required for a Terraform state bucket in this assignment and would add unnecessary moving parts.
#checkov:skip=CKV_AWS_18: Access logging is omitted because this bucket stores Terraform state only and the assignment prioritizes a minimal free-tier backend.
#checkov:skip=CKV2_AWS_61: Lifecycle rules are intentionally left out because the backend state bucket stores a very small amount of versioned state data.
#checkov:skip=CKV_AWS_145: AES256 server-side encryption is sufficient for this assignment backend and avoids introducing a customer-managed KMS key.
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

#checkov:skip=CKV_AWS_119: The Terraform lock table uses AWS-managed encryption to keep the backend simple and avoid an extra CMK for this assignment.
#checkov:skip=CKV_AWS_28: Point-in-time recovery is intentionally omitted because this table is used only for transient Terraform state locking.
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

#checkov:skip=CKV2_AWS_34: This parameter stores non-sensitive environment metadata, so a plain String parameter keeps the demo simpler.
resource "aws_ssm_parameter" "app_config" {
  name  = local.config_parameter_name
  type  = "String"
  value = "{\"environment\":\"${var.environment}\"}"
  tags  = local.tags
}

#checkov:skip=CKV_AWS_149: A customer-managed KMS key is intentionally not added because this secret container is only a placeholder reference for the assignment.
#checkov:skip=CKV2_AWS_57: Automatic rotation is not enabled because no live rotating application secret is managed by Terraform in this demo.
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
  github_environment      = var.environment
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
