locals {
  dashboard_name = "${var.name_prefix}-overview"
}

#checkov:skip=CKV_AWS_158: CloudWatch Logs uses the default service-managed encryption because introducing a CMK would add unnecessary complexity for this assignment.
#checkov:skip=CKV_AWS_338: Log retention is set to 14 days to control free-tier log storage costs during the demo period.
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

#checkov:skip=CKV_AWS_26: SNS uses default service-managed encryption to keep the alerting setup simple for the assignment.
resource "aws_sns_topic" "alerts" {
  name = "${var.name_prefix}-alerts"
  tags = var.tags
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_metric_alarm" "high_error_rate" {
  alarm_name          = "${var.name_prefix}-high-error-rate"
  alarm_description   = "High error rate for ${var.lambda_function_name}. Runbook: ${var.runbook_url}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 5
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  metric_query {
    id          = "errors"
    return_data = false
    metric {
      namespace   = "AWS/Lambda"
      metric_name = "Errors"
      period      = 300
      stat        = "Sum"
      dimensions = {
        FunctionName = var.lambda_function_name
      }
    }
  }

  metric_query {
    id          = "invocations"
    return_data = false
    metric {
      namespace   = "AWS/Lambda"
      metric_name = "Invocations"
      period      = 300
      stat        = "Sum"
      dimensions = {
        FunctionName = var.lambda_function_name
      }
    }
  }

  metric_query {
    id          = "error_rate"
    expression  = "IF(invocations>0,(errors/invocations)*100,0)"
    label       = "Error Rate"
    return_data = true
  }

  tags = var.tags
}

resource "aws_cloudwatch_dashboard" "lambda" {
  dashboard_name = local.dashboard_name

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        width  = 12
        height = 6
        x      = 0
        y      = 0
        properties = {
          title   = "Invocation Count"
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          period  = 300
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", var.lambda_function_name]
          ]
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        x      = 12
        y      = 0
        properties = {
          title  = "Error Rate"
          view   = "timeSeries"
          region = var.aws_region
          period = 300
          metrics = [
            [{ expression = "IF(m2>0,(m1/m2)*100,0)", label = "Error Rate %", id = "e1" }],
            ["AWS/Lambda", "Errors", "FunctionName", var.lambda_function_name, { id = "m1", visible = false }],
            [".", "Invocations", ".", ".", { id = "m2", visible = false }],
          ]
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        x      = 0
        y      = 6
        properties = {
          title  = "Duration P50 and P95"
          view   = "timeSeries"
          region = var.aws_region
          period = 300
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", var.lambda_function_name, { stat = "p50" }],
            [".", "Duration", ".", ".", { stat = "p95" }],
          ]
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        x      = 12
        y      = 6
        properties = {
          title  = "Throttle Count"
          view   = "timeSeries"
          region = var.aws_region
          period = 300
          metrics = [
            ["AWS/Lambda", "Throttles", "FunctionName", var.lambda_function_name]
          ]
        }
      },
      {
        type   = "metric"
        width  = 24
        height = 6
        x      = 0
        y      = 12
        properties = {
          title  = "Items Created Custom Metric"
          view   = "timeSeries"
          region = var.aws_region
          period = 300
          metrics = [
            [var.custom_metric_namespace, var.custom_metric_name, "FunctionName", var.lambda_function_name]
          ]
        }
      }
    ]
  })
}
