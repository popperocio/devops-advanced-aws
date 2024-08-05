data "archive_file" "lambda_zip_file" {
  type        = "zip"
  source_file = "/app/main.py"
  output_path = "main.zip"
}

resource "aws_iam_role" "lambda_role" {
  name        = "lambda-ex"
  description = "IAM role for Lambda function"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect = "Allow"
      }
    ]
  })
}

resource "aws_lambda_function" "lambda_function_backend" {
  filename         = data.archive_file.lambda_zip_file.output_path
  function_name    = "lambda_function_backend"
  role             = aws_iam_role.lambda_role.arn
  handler          = "main.handler" 
  runtime          = "python3.8"
  source_code_hash = data.archive_file.lambda_zip_file.output_base64sha256
}

resource "aws_lambda_function_url" "lambda_function_url" {
  function_name      = aws_lambda_function.lambda_function_backend.function_name
  authorization_type = "NONE"
}

output "lambda_function_url" {
  value = aws_lambda_function_url.lambda_function_url.function_url
}

