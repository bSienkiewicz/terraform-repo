# 1. archive the code

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/lambda.zip"
}
# 2. create the IAM role
resource "aws_iam_role" "lambda_role" {
  name = "visitor_processor_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# 3. attach the necessary policies
resource "aws_iam_role_policy" "lambda_policy" {
  name = "visitor_processor_policy"
  role = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      # Grant permission to read/delete messages from your SQS queue
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.visitor_queue.arn
      },
      # Grant permission to put items into your DynamoDB table
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem"
        ]
        Resource = aws_dynamodb_table.visitor_logs.arn
      },
    ]
  })
}

# 4. deploy the lambda function
resource "aws_lambda_function" "visitor_processor" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "visitor_processor"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.visitor_logs.name
    }
  }

  tags = {
    Name        = "Visitor Processor"
    Environment = "Dev"
  }
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.visitor_queue.arn
  function_name    = aws_lambda_function.visitor_processor.arn
  batch_size       = 10 # Process up to 10 messages at a time
}