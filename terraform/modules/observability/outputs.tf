output "log_group_name" {
  description = "Name of the Lambda CloudWatch Log Group."
  value       = aws_cloudwatch_log_group.lambda.name
}

output "log_group_arn" {
  description = "ARN of the Lambda CloudWatch Log Group."
  value       = aws_cloudwatch_log_group.lambda.arn
}

output "dashboard_name" {
  description = "CloudWatch dashboard name."
  value       = aws_cloudwatch_dashboard.lambda.dashboard_name
}

output "sns_topic_arn" {
  description = "SNS topic ARN used for alert notifications."
  value       = aws_sns_topic.alerts.arn
}

output "alarm_name" {
  description = "CloudWatch alarm name for high error rate."
  value       = aws_cloudwatch_metric_alarm.high_error_rate.alarm_name
}
