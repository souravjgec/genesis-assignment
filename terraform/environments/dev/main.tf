data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  name_prefix = var.function_name
  owner_tag   = trimspace(replace(replace(var.owner, "<", ""), ">", ""))
  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
    Owner       = local.owner_tag
  }
  config_parameter_name     = "/genesis/${var.environment}/app-config"
  lambda_runtime            = "python3.12"
  lambda_timeout_seconds    = 10
  lambda_memory_size_mb     = 256
  custom_metric_namespace   = "Genesis/ItemsApi"
  custom_metric_name        = "ItemsCreated"
  log_retention_days        = 365
  runbook_url               = var.runbook_url != "" ? var.runbook_url : "https://github.com/${var.github_repo}/blob/main/docs/runbooks/high-error-rate.md"
  account_root_arn          = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
  state_logs_bucket_name    = "${local.name_prefix}-tf-state-logs"
  state_replica_bucket_name = "${local.name_prefix}-tf-state-replica"
}

resource "aws_kms_key" "application" {
  description         = "Customer managed KMS key for Lambda environment variables and configuration data."
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableAccountAdministration"
        Effect    = "Allow"
        Principal = { AWS = local.account_root_arn }
        Action    = "kms:*"
        Resource  = "*"
      },
    ]
  })

  tags = local.tags
}

resource "aws_kms_alias" "application" {
  name          = "alias/${local.name_prefix}-application"
  target_key_id = aws_kms_key.application.key_id
}

resource "aws_kms_key" "state" {
  description         = "Customer managed KMS key for Terraform state and lock data."
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableAccountAdministration"
        Effect    = "Allow"
        Principal = { AWS = local.account_root_arn }
        Action    = "kms:*"
        Resource  = "*"
      },
    ]
  })

  tags = local.tags
}

resource "aws_kms_alias" "state" {
  name          = "alias/${local.name_prefix}-state"
  target_key_id = aws_kms_key.state.key_id
}

resource "aws_kms_key" "observability" {
  description         = "Customer managed KMS key for logs and notifications."
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableAccountAdministration"
        Effect    = "Allow"
        Principal = { AWS = local.account_root_arn }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid    = "AllowCloudWatchLogsUsage"
        Effect = "Allow"
        Principal = {
          Service = "logs.${var.aws_region}.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:GenerateDataKey*",
          "kms:ReEncrypt*",
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowSnsUsage"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey*",
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:CallerAccount" = data.aws_caller_identity.current.account_id
            "kms:ViaService"    = "sns.${var.aws_region}.amazonaws.com"
          }
        }
      },
    ]
  })

  tags = local.tags
}

resource "aws_kms_alias" "observability" {
  name          = "alias/${local.name_prefix}-observability"
  target_key_id = aws_kms_key.observability.key_id
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "${local.name_prefix}-tf-state"
  tags   = local.tags
}

resource "aws_s3_bucket" "terraform_state_logs" {
  bucket = local.state_logs_bucket_name
  tags   = local.tags
}

resource "aws_s3_bucket" "terraform_state_replica" {
  bucket = local.state_replica_bucket_name
  tags   = local.tags
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state_logs" {
  bucket = aws_s3_bucket.terraform_state_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state_replica" {
  bucket = aws_s3_bucket.terraform_state_replica.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.state.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_logs" {
  bucket = aws_s3_bucket.terraform_state_logs.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.state.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_replica" {
  bucket = aws_s3_bucket.terraform_state_replica.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.state.arn
      sse_algorithm     = "aws:kms"
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

resource "aws_s3_bucket_public_access_block" "terraform_state_logs" {
  bucket = aws_s3_bucket.terraform_state_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "terraform_state_replica" {
  bucket = aws_s3_bucket.terraform_state_replica.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "expire-incomplete-multipart-uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "terraform_state_logs" {
  bucket = aws_s3_bucket.terraform_state_logs.id

  rule {
    id     = "expire-access-logs"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    expiration {
      days = 90
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "terraform_state_replica" {
  bucket = aws_s3_bucket.terraform_state_replica.id

  rule {
    id     = "retain-replicated-state"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

resource "aws_s3_bucket_logging" "terraform_state" {
  bucket        = aws_s3_bucket.terraform_state.id
  target_bucket = aws_s3_bucket.terraform_state_logs.id
  target_prefix = "access/"
}

resource "aws_s3_bucket_logging" "terraform_state_replica" {
  bucket        = aws_s3_bucket.terraform_state_replica.id
  target_bucket = aws_s3_bucket.terraform_state_logs.id
  target_prefix = "replica-access/"
}

data "aws_iam_policy_document" "terraform_state_log_delivery" {
  statement {
    sid = "AllowS3ServerAccessLogs"
    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.terraform_state_logs.arn}/access/*"]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = [
        aws_s3_bucket.terraform_state.arn,
        aws_s3_bucket.terraform_state_replica.arn,
      ]
    }
  }

  statement {
    sid = "AllowReplicaAccessLogs"
    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.terraform_state_logs.arn}/replica-access/*"]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.terraform_state_replica.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "terraform_state_logs" {
  bucket = aws_s3_bucket.terraform_state_logs.id
  policy = data.aws_iam_policy_document.terraform_state_log_delivery.json
}

resource "aws_sns_topic" "terraform_state_events" {
  name              = "${local.name_prefix}-tf-state-events"
  kms_master_key_id = aws_kms_key.observability.arn
  tags              = local.tags
}

data "aws_iam_policy_document" "terraform_state_events" {
  statement {
    sid = "AllowS3BucketNotifications"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.terraform_state_events.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values = [
        aws_s3_bucket.terraform_state.arn,
        aws_s3_bucket.terraform_state_logs.arn,
        aws_s3_bucket.terraform_state_replica.arn,
      ]
    }
  }
}

resource "aws_sns_topic_policy" "terraform_state_events" {
  arn    = aws_sns_topic.terraform_state_events.arn
  policy = data.aws_iam_policy_document.terraform_state_events.json
}

resource "aws_s3_bucket_notification" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  topic {
    topic_arn = aws_sns_topic.terraform_state_events.arn
    events    = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
  }

  depends_on = [aws_sns_topic_policy.terraform_state_events]
}

resource "aws_s3_bucket_notification" "terraform_state_logs" {
  bucket = aws_s3_bucket.terraform_state_logs.id

  topic {
    topic_arn = aws_sns_topic.terraform_state_events.arn
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_sns_topic_policy.terraform_state_events]
}

resource "aws_s3_bucket_notification" "terraform_state_replica" {
  bucket = aws_s3_bucket.terraform_state_replica.id

  topic {
    topic_arn = aws_sns_topic.terraform_state_events.arn
    events    = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
  }

  depends_on = [aws_sns_topic_policy.terraform_state_events]
}

data "aws_iam_policy_document" "terraform_state_replication_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "terraform_state_replication" {
  name               = "${local.name_prefix}-tf-state-replication"
  assume_role_policy = data.aws_iam_policy_document.terraform_state_replication_assume_role.json
  tags               = local.tags
}

data "aws_iam_policy_document" "terraform_state_replication" {
  statement {
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.terraform_state.arn,
      aws_s3_bucket.terraform_state_logs.arn,
    ]
  }

  statement {
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]
    resources = [
      "${aws_s3_bucket.terraform_state.arn}/*",
      "${aws_s3_bucket.terraform_state_logs.arn}/*",
    ]
  }

  statement {
    actions = [
      "s3:ReplicateDelete",
      "s3:ReplicateObject",
      "s3:ReplicateTags",
      "s3:ObjectOwnerOverrideToBucketOwner",
    ]
    resources = ["${aws_s3_bucket.terraform_state_replica.arn}/*"]
  }

  statement {
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey",
    ]
    resources = [aws_kms_key.state.arn]
  }
}

resource "aws_iam_role_policy" "terraform_state_replication" {
  name   = "${local.name_prefix}-tf-state-replication"
  role   = aws_iam_role.terraform_state_replication.id
  policy = data.aws_iam_policy_document.terraform_state_replication.json
}

resource "aws_s3_bucket_replication_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  role   = aws_iam_role.terraform_state_replication.arn

  rule {
    id     = "replicate-terraform-state"
    status = "Enabled"

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }

    destination {
      bucket        = aws_s3_bucket.terraform_state_replica.arn
      storage_class = "STANDARD"

      encryption_configuration {
        replica_kms_key_id = aws_kms_key.state.arn
      }
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.terraform_state,
    aws_s3_bucket_versioning.terraform_state_replica,
  ]
}

resource "aws_s3_bucket_replication_configuration" "terraform_state_logs" {
  bucket = aws_s3_bucket.terraform_state_logs.id
  role   = aws_iam_role.terraform_state_replication.arn

  rule {
    id     = "replicate-access-logs"
    status = "Enabled"

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }

    destination {
      bucket        = aws_s3_bucket.terraform_state_replica.arn
      storage_class = "STANDARD"

      encryption_configuration {
        replica_kms_key_id = aws_kms_key.state.arn
      }
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.terraform_state_logs,
    aws_s3_bucket_versioning.terraform_state_replica,
  ]
}

resource "aws_dynamodb_table" "terraform_lock" {
  name         = "${local.name_prefix}-tf-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.state.arn
  }

  tags = local.tags
}

resource "aws_ssm_parameter" "app_config" {
  name   = local.config_parameter_name
  type   = "SecureString"
  key_id = aws_kms_key.application.arn
  value  = jsonencode({ environment = var.environment })
  tags   = local.tags
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
  kms_key_arn             = aws_kms_key.observability.arn
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
  kms_key_arns            = [aws_kms_key.application.arn]
  tags                    = local.tags
}

module "compute" {
  source = "../../modules/compute"

  function_name           = local.name_prefix
  lambda_role_arn         = module.iam.lambda_execution_role_arn
  lambda_role_name        = module.iam.lambda_execution_role_name
  runtime                 = local.lambda_runtime
  timeout_seconds         = local.lambda_timeout_seconds
  memory_size_mb          = local.lambda_memory_size_mb
  config_parameter_name   = aws_ssm_parameter.app_config.name
  kms_key_arn             = aws_kms_key.application.arn
  custom_metric_namespace = local.custom_metric_namespace
  custom_metric_name      = local.custom_metric_name
  tags                    = local.tags
}
