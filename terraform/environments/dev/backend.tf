terraform {
  backend "s3" {
    bucket         = "genesis-api-dev-tf-state"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "genesis-api-dev-tf-lock"
    encrypt        = true
  }
}
