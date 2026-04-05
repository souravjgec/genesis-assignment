terraform {
  required_version = ">= 1.6.0"

  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.5"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.28.0"
    }
  }

  # Bootstrap note:
  # The S3 bucket and DynamoDB table below are created by this configuration.
  # Run the initial apply with the default local state, then migrate to an S3
  # backend using those resources for subsequent runs.
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.tags
  }
}
