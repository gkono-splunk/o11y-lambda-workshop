# Output value definitions


output "lambda_bucket_name" {
  description = "S3 Bucket"

  value = aws_s3_bucket.lambda_bucket.id
}

output "producer_function_name" {
  description = "Lambda Producer"

  value = aws_lambda_function.lambda_producer.function_name
}

output "consumer_function_name" {
  description = "Lambda Consumer"

  value = aws_lambda_function.lambda_consumer.function_name
}

output "base_url" {
  description = "Endpoint"

  value = "${aws_apigatewayv2_stage.lambda.invoke_url}/producer"
}

output "environment" {
  description = "Deployment Environment"

  value = "${var.prefix}-lambda-shop"
}