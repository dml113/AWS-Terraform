# filter를 생성할 때 permmsion 오류가 뜨면 account id와 region을 확인한다.

resource "aws_cloudwatch_log_group" "cloudtrail_log_group" {
  name = "busan_wsc2024-gvn-LG"
}

resource "aws_iam_role" "cloudtrail_role" {
  name               = "busan_wsc2024-cloudtrail-role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "cloudtrail.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudtrail_policy_attachment" {
  role       = aws_iam_role.cloudtrail_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCloudTrail_FullAccess"
}

resource "aws_iam_policy" "cloudtrail_cloudwatch_policy" {
  name   = "busan_wsc2024-cloudtrail-cloudwatch-policy"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource": "${aws_cloudwatch_log_group.cloudtrail_log_group.arn}:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudtrail_cloudwatch_policy_attachment" {
  role       = aws_iam_role.cloudtrail_role.name
  policy_arn = aws_iam_policy.cloudtrail_cloudwatch_policy.arn
}

resource "random_pet" "bucket_name" {
  length = 4
  separator = "-"
}

resource "aws_s3_bucket" "wsc2024_ct_bucket_0410" {
  bucket = "${random_pet.bucket_name.id}-gmst"
}

resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  bucket = aws_s3_bucket.wsc2024_ct_bucket_0410.id

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "cloudtrail.amazonaws.com"
        },
        "Action": [
          "s3:GetBucketAcl",
          "s3:ListBucket"
        ],
        "Resource": "arn:aws:s3:::${aws_s3_bucket.wsc2024_ct_bucket_0410.id}"
      },
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "cloudtrail.amazonaws.com"
        },
        "Action": [
          "s3:PutObject"
        ],
        "Resource": "arn:aws:s3:::${aws_s3_bucket.wsc2024_ct_bucket_0410.id}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
        "Condition": {
          "StringEquals": {
            "s3:x-amz-acl": "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_cloudtrail" "cloud_trail" {
  name                          = "wsi-project-trail"
  s3_bucket_name                = aws_s3_bucket.wsc2024_ct_bucket_0410.id
  enable_log_file_validation    = true
  include_global_service_events = true
  is_multi_region_trail         = true

  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_role.arn
  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail_log_group.arn}:*"
}

######################################################################
#                                                                    #
#                               Lambda                               #
#                                                                    #
######################################################################

resource "aws_iam_role" "lambda_role" {
  name = "wsi-project-log-function-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "lambda_execution_policy" {
  name        = "busan_lambda_execution_policy"
  description = "Policy for Lambda execution"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Action    = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      },
      {
        Effect    = "Allow",
        Action    = [
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "iam:DetachRolePolicy"
        ],
        Resource = "*"
      },
      {
        Effect    = "Allow",
        Action    = "lambda:InvokeFunction",
        Resource  = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_execution_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_execution_policy.arn
}

resource "aws_cloudwatch_log_group" "user_login_logs" {
  name = "wsi-project-login"

  tags = {
    "Name" = "wsi-project-login"
  }
}

resource "aws_cloudwatch_log_stream" "user_log_stream" {
  log_group_name = aws_cloudwatch_log_group.user_login_logs.name
  name           = "wsi-project-login-stream"
}

resource "aws_lambda_function" "wsc2024_gvn_lambda" {
  function_name    = "wsi-project-log-function"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  filename         = "./files/07Busan/02/lambda_function.zip"
  source_code_hash = filebase64sha256("./files/07Busan/02/lambda_function.zip")
  timeout          = 10

  environment {
    variables = {
      LOG_GROUP_NAME  = aws_cloudwatch_log_group.user_login_logs.name
      LOG_STREAM_NAME = aws_cloudwatch_log_stream.user_log_stream.name
    }
  }
}

resource "aws_cloudwatch_log_subscription_filter" "lambda_log_subscription_filter" {
  name            = "busan_wsc2024-gvn-log-subscription-filter"
  log_group_name  = aws_cloudwatch_log_group.cloudtrail_log_group.name
  filter_pattern  = "{ $.eventName = ConsoleLogin }"
  destination_arn = aws_lambda_function.wsc2024_gvn_lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.wsc2024_gvn_lambda.function_name
  principal     = "logs.amazonaws.com"
  source_arn    = "arn:aws:logs:ap-northeast-2:${data.aws_caller_identity.current.account_id}:log-group:*:*"  # region과 account id를 알아서 변경한다.
}