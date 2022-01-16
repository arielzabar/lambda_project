provider "aws" {
  region     = var.region
  profile = "default"
}

data "aws_caller_identity" "current" {
}

data "aws_region" "current" {
}

resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
  versioning {
    enabled = false
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "lambda-code.py"
  output_path = "lambda-code.zip"
}

resource "aws_lambda_function" "lambda_function" {
  function_name    = var.lambda_function_name
  handler          = "lambda-code.lambda_handler"
  role             = aws_iam_role.lambda_role.arn
  runtime          = var.runtime
  source_code_hash = "data.archive_file.lambda_zip.output_base64sha256"
  filename         = "lambda-code.zip"
  timeout          = 900
  layers           = [aws_lambda_layer_version.lambda_layer.arn]

  dynamic "environment" {
    for_each = length(keys(var.custom_lambda_env_vars)) == 0 ? [] : [true]
    content {
      variables = var.custom_lambda_env_vars
    }
  }
}
