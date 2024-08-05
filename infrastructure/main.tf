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


#****************************** FRONTEND ********************************************

resource "aws_s3_bucket" "frontend_bucket" {
  bucket = "frontend-bucket-pokemon-app"
  tags = {
    Name = "Frontend Bucket"
  }
}

resource "aws_s3_object" "object" {
  bucket = aws_s3_bucket.frontend_bucket.id
  key    = "index.html"
  source = "/ui/build/index.html"
  acl    = "public-read"
  depends_on = [aws_s3_bucket.frontend_bucket]
}

resource "aws_s3_bucket_policy" "frontend_bucket_policy" {
  bucket = aws_s3_bucket.frontend_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = "s3:GetObject"
        Resource = "${aws_s3_bucket.frontend_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_public_access_block" "frontend_bucket_public_access" {
  bucket = aws_s3_bucket.frontend_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "s3_bucket_url" {
  value = "http://localhost:4566/${aws_s3_bucket.frontend_bucket.bucket}/index.html"
}
