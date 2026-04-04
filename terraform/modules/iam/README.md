# IAM Module

Creates the IAM resources required for the Genesis assignment Lambda deployment path:

- GitHub Actions OIDC provider
- GitHub Actions deploy role with least-privilege Lambda code update permissions
- Lambda execution role with access to CloudWatch Logs, custom metrics, SSM, and Secrets Manager

## Inputs

| Name | Type | Description |
| --- | --- | --- |
| `name_prefix` | `string` | Prefix used for IAM resource names. |
| `github_repository` | `string` | Repository in `owner/name` format allowed to assume the deploy role. |
| `github_main_branch` | `string` | Branch allowed to deploy through OIDC. Defaults to `main`. |
| `github_environment` | `string` | GitHub Actions environment allowed to deploy through OIDC. Defaults to `dev`. |
| `lambda_function_name` | `string` | Lambda function name the deploy role can update. |
| `aws_region` | `string` | AWS region where the Lambda function runs. |
| `log_group_arn` | `string` | CloudWatch Log Group ARN used by the Lambda function. |
| `custom_metric_namespace` | `string` | CloudWatch namespace used for application custom metrics. |
| `config_parameter_arn` | `string` | SSM parameter ARN readable by the Lambda function. |
| `secret_arn` | `string` | Secrets Manager secret ARN readable by the Lambda function. |
| `tags` | `map(string)` | Tags applied to IAM resources. |

## Outputs

| Name | Description |
| --- | --- |
| `lambda_execution_role_arn` | ARN of the Lambda execution role. |
| `lambda_execution_role_name` | Name of the Lambda execution role. |
| `github_actions_role_arn` | ARN of the GitHub Actions deploy role. |
| `github_oidc_provider_arn` | ARN of the GitHub OIDC provider. |
