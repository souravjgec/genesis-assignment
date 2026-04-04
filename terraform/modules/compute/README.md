# Compute Module

Creates the AWS Lambda function used by the Genesis assignment.

The module packages a tiny bootstrap handler so Terraform can create the function on first apply. The CI/CD workflow later replaces that bootstrap package with the real application zip using `aws lambda update-function-code`.

It also creates a public Lambda Function URL so the smoke test can call `/health` after deployment.

## Inputs

| Name | Type | Description |
| --- | --- | --- |
| `function_name` | `string` | Name of the Lambda function. |
| `lambda_role_arn` | `string` | Execution role ARN for the function. |
| `runtime` | `string` | Lambda runtime identifier. |
| `timeout_seconds` | `number` | Lambda timeout in seconds. |
| `memory_size_mb` | `number` | Lambda memory size in MB. |
| `architecture` | `string` | Lambda architecture. |
| `config_parameter_name` | `string` | SSM parameter name exposed to the function. |
| `secret_arn` | `string` | Secrets Manager secret ARN exposed to the function. |
| `custom_metric_namespace` | `string` | Namespace for custom CloudWatch metrics. |
| `custom_metric_name` | `string` | Name of the custom metric emitted by the application. |
| `tags` | `map(string)` | Tags applied to the function. |

## Outputs

| Name | Description |
| --- | --- |
| `lambda_function_arn` | ARN of the Lambda function. |
| `lambda_function_name` | Name of the Lambda function. |
| `lambda_invoke_arn` | Invoke ARN of the Lambda function. |
| `lambda_function_url` | Public Lambda Function URL used as the API base URL. |
