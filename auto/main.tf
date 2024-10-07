provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      o11y-workshop = "lambda-tracing"
    }
  }
}

# Create IAM Role
resource "aws_iam_role" "lambda_kinesis" {
  name = "lambda_kinesis"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}


# Attach IAM Policies for Lambda and Kinesis
resource "aws_iam_role_policy_attachment" "lambda_all_policy" {
  role = aws_iam_role.lambda_kinesis.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_basic_policy" {
  role = aws_iam_role.lambda_kinesis.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "kinesis_all_policy" {
  role = aws_iam_role.lambda_kinesis.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonKinesisFullAccess"
}


# Create S3 Bucket Name, Bucket, Ownership, ACL
resource "random_pet" "lambda_bucket_name" {
  prefix = "lambda-shop"
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = random_pet.lambda_bucket_name.id
}

resource "aws_s3_bucket_ownership_controls" "lambda_bucket" {
  bucket = aws_s3_bucket.lambda_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "lambda_bucket" {
  depends_on = [aws_s3_bucket_ownership_controls.lambda_bucket]

  bucket = aws_s3_bucket.lambda_bucket.id
  acl    = "private"
}


# Package Producer and Consumer Apps, Upload to S3 Bucket
data "archive_file" "producer_app" {
  type = "zip"

  source_file  = "${path.module}/handler/auto_producer.mjs"
  output_path = "${path.module}/lambda_producer.zip"
}

resource "aws_s3_object" "producer_app" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "lambda_producer.zip"
  source = data.archive_file.producer_app.output_path

  etag = filemd5(data.archive_file.producer_app.output_path)
}

data "archive_file" "consumer_app" {
  type = "zip"

  source_file  = "${path.module}/handler/auto_consumer.mjs"
  output_path = "${path.module}/lambda_consumer.zip"
}

resource "aws_s3_object" "consumer_app" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "lambda_consumer.zip"
  source = data.archive_file.consumer_app.output_path

  etag = filemd5(data.archive_file.consumer_app.output_path)
}


# Create Lambda Functions
resource "aws_lambda_function" "lambda_producer" {
  function_name = "myProducer"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.producer_app.key

  runtime = "nodejs20.x"
  handler = "auto_producer.producer"

  source_code_hash = data.archive_file.producer_app.output_base64sha256

  role = aws_iam_role.lambda_kinesis.arn

  environment {
    variables = {
      SPLUNK_ACCESS_TOKEN = "wSLOU3EIWLTOruPYkpymKw"
      SPLUNK_REALM = "us1"
      OTEL_SERVICE_NAME = "producer-lambda"
      OTEL_RESOURCE_ATTRIBUTES = "deployment.environment=lambda-shop"
      AWS_LAMBDA_EXEC_WRAPPER = "/opt/nodejs-otel-handler"
      KINESIS_STREAM = aws_kinesis_stream.lambda_streamer.name
    }
  }

  layers = ["arn:aws:lambda:us-east-1:254067382080:layer:splunk-apm:108"]

  timeout = 60
}

resource "aws_lambda_function" "lambda_consumer" {
  function_name = "myConsumer"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.consumer_app.key

  runtime = "nodejs20.x"
  handler = "auto_consumer.consumer"

  source_code_hash = data.archive_file.consumer_app.output_base64sha256

  role = aws_iam_role.lambda_kinesis.arn

  environment {
    variables = {
      SPLUNK_ACCESS_TOKEN = "wSLOU3EIWLTOruPYkpymKw"
      SPLUNK_REALM = "us1"
      OTEL_SERVICE_NAME = "consumer-lambda"
      OTEL_RESOURCE_ATTRIBUTES = "deployment.environment=lambda-shop"
      AWS_LAMBDA_EXEC_WRAPPER = "/opt/nodejs-otel-handler"
    }
  }

  layers = ["arn:aws:lambda:us-east-1:254067382080:layer:splunk-apm:108"]

  timeout = 60
}

# Add API Gateway API, Stage, Integration, Route and Permission Resources
resource "aws_apigatewayv2_api" "lambda" {
  name          = "serverless_gateway"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  name        = "serverless_stage"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = aws_lambda_function.lambda_producer.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "POST /producer"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# Lambda Permission for API Gateway
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_producer.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}

# CloudWatch Log Groups for Lambda and API Gateway
resource "aws_cloudwatch_log_group" "lambda_producer" {
  name = "/aws/lambda/${aws_lambda_function.lambda_producer.function_name}"

  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "lambda_consumer" {
  name = "/aws/lambda/${aws_lambda_function.lambda_consumer.function_name}"

  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.lambda.name}"

  retention_in_days = 30
}

# Kinesis Data Stream
resource "aws_kinesis_stream" "lambda_streamer" {
    name = "lambda_streamer"
    shard_count = 1
    retention_period = 24
    shard_level_metrics = [
        "IncomingBytes",
        "OutgoingBytes"
    ]
    tags = {
        o11y-workshop = "lambda-tracing"
    }
}

# Source Mapping Lambda Consumer to Kinesis Stream
resource "aws_lambda_event_source_mapping" "kinesis_lambda_event_mapping" {
    batch_size = 100
    event_source_arn = aws_kinesis_stream.lambda_streamer.arn
    enabled = true
    function_name = aws_lambda_function.lambda_consumer.arn
    starting_position = "LATEST"
}