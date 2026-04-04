# Dev Environment

This root module wires the AWS Lambda deployment path for the assignment:

- Terraform state S3 bucket with versioning, encryption, and public access block
- DynamoDB lock table with `PAY_PER_REQUEST`
- SSM parameter and Secrets Manager secret references for runtime configuration
- IAM module for Lambda execution and GitHub OIDC deploy access
- Compute module for the Lambda function
- Observability module for logs, dashboard, SNS, and alarming

## Bootstrap Flow

1. Run the first `terraform init` and `terraform apply` with local state.
2. Note the generated S3 bucket and DynamoDB table outputs.
3. Add an S3 backend block or `-backend-config` values and run `terraform init -migrate-state`.

This two-step flow avoids the chicken-and-egg problem of trying to use a remote backend before the backend resources exist.

## Example Commands

```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
```
