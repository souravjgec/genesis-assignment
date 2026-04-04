# Observability Module

Creates the CloudWatch and SNS resources required for the assignment:

- Lambda CloudWatch Log Group with explicit retention
- CloudWatch dashboard with invocation, error rate, p50/p95 duration, throttles, and a custom metric widget
- SNS topic with email subscription
- High-error-rate CloudWatch alarm with a runbook reference in the description

## Inputs

| Name | Type | Description |
| --- | --- | --- |
| `name_prefix` | `string` | Prefix used for resource names. |
| `lambda_function_name` | `string` | Lambda function name being monitored. |
| `aws_region` | `string` | AWS region shown in dashboard widgets. |
| `alert_email` | `string` | Email endpoint subscribed to the SNS topic. |
| `runbook_url` | `string` | Runbook URL included in the alarm description. |
| `log_retention_days` | `number` | CloudWatch Log Group retention in days. |
| `custom_metric_namespace` | `string` | Namespace for the custom metric. |
| `custom_metric_name` | `string` | Name of the custom metric. |
| `tags` | `map(string)` | Tags applied to observability resources. |

## Outputs

| Name | Description |
| --- | --- |
| `log_group_name` | Lambda CloudWatch Log Group name. |
| `log_group_arn` | Lambda CloudWatch Log Group ARN. |
| `dashboard_name` | CloudWatch dashboard name. |
| `sns_topic_arn` | SNS topic ARN for alerts. |
| `alarm_name` | High-error-rate alarm name. |
