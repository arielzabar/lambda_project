resource "aws_db_instance" "default" {
  allocated_storage                   = 10
  engine                              = "mysql"
  engine_version                      = "5.7"
  instance_class                      = "db.t3.micro"
  name                                = "mydb"
  username                            = "arielle"
  password                            = "ariellepass"
  parameter_group_name                = "default.mysql5.7"
  skip_final_snapshot                 = true
  identifier                          = "mydb"
  publicly_accessible                 = true
  iam_database_authentication_enabled = true
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucket.arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda_function.arn
    events              = ["s3:ObjectCreated:*"]
  }
  depends_on = [aws_lambda_permission.allow_bucket]
}

resource "aws_lambda_layer_version" "lambda_layer" {
  filename            = "lambda_rds_layer.zip"
  layer_name          = "lambda_layer_new"
  compatible_runtimes = [var.runtime]
}