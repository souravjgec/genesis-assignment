output "lambda_function_arn" {
  description = "ARN of the Lambda function."
  value       = aws_lambda_function.this.arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function."
  value       = aws_lambda_function.this.function_name
}

output "lambda_invoke_arn" {
  description = "Invoke ARN of the Lambda function."
  value       = aws_lambda_function.this.invoke_arn
}

output "lambda_function_url" {
  description = "Public Function URL for the Lambda."
  value       = aws_lambda_function_url.this.function_url
}
