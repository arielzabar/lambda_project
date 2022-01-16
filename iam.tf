
resource "aws_iam_role" "lambda_role" {
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  name               = var.lambda_role_name
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    sid    = "AssumeInstanceRole"
    effect = "Allow"

    principals {
      type = "Service"

      identifiers = [
        "lambda.amazonaws.com",
      ]
    }

    actions = [
      "sts:AssumeRole",
    ]
  }
}

data "aws_iam_policy_document" "lambda_role_access_doc" {
  statement {
    sid    = "AllowLambdaBucketPermissions"
    effect = "Allow"

    actions = [
      "s3:*",
    ]

    resources = [
      "${aws_s3_bucket.bucket.arn}/*"
    ]

    condition {
      test     = "StringLike"
      variable = "aws:userid"

      values = [
        "${aws_iam_role.lambda_role.unique_id}:*",
      ]
    }
  }
  statement {
    sid    = "LambdaLogsForMonitoring"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:*"
    ]

    condition {
      test     = "StringLike"
      variable = "aws:userid"

      values = [
        "${aws_iam_role.lambda_role.unique_id}:*",
      ]
    }
  }
  statement {
    sid    = "AllowLambdaIamAuthToRds"
    effect = "Allow"
    actions = [
      "rds-db:connect",
    ]
    resources = [
      "arn:aws:rds-db:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:dbuser:*/*"
    ]
  }
}

resource "aws_iam_policy" "lambda_role_s3_access_policy" {
  name   = "lambda_role_s3_access"
  policy = data.aws_iam_policy_document.lambda_role_access_doc.json
}

data "aws_iam_user" "database_local" {
  user_name = "database-role"
}

resource "aws_iam_policy_attachment" "lambda_role_s3_access_att" {
  name = "lambda_role_s3_access"

  roles = [
    aws_iam_role.lambda_role.name,
  ]

  policy_arn = aws_iam_policy.lambda_role_s3_access_policy.arn
}


//testing user
//data "aws_iam_policy_document" "database_local" {
//  statement {
//    sid    = "AllowLambdaIamAuthToRds"
//    effect = "Allow"
//    actions = [
//      "rds-db:connect",
//    ]
//    resources = [
//      "arn:aws:rds-db:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:dbuser:*/*"
//
//    ]
//  }
//}
//
//resource "aws_iam_policy" "database_local_policy" {
//  name   = "database_local"
//  policy = data.aws_iam_policy_document.database_local.json
//}
//
//resource "aws_iam_policy_attachment" "database_local_att" {
//  name  = "lambda_role_s3_access"
//  users = [data.aws_iam_user.database_local.user_name, ]
//
//  policy_arn = aws_iam_policy.database_local_policy.arn
//}
