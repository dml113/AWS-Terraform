resource "aws_cloudwatch_log_group" "cloudtrail_log_group" {
  name = "/cg/ssm/logs"
}

resource "aws_iam_role" "cloudtrail_role" {
  name               = "cg-cloudtrail-role"
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
  name   = "jeju-wsc2024-cloudtrail-cloudwatch-policy"
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
        "Resource": "arn:aws:s3:::${aws_s3_bucket.wsc2024_ct_bucket_0410.id}/*",
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
  name                          = "cg-rule"
  s3_bucket_name                = aws_s3_bucket.wsc2024_ct_bucket_0410.id
  enable_log_file_validation    = true
  include_global_service_events = true
  is_multi_region_trail         = true

  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_role.arn
  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail_log_group.arn}:*"
}

# 지표 필터 생성
resource "aws_cloudwatch_log_metric_filter" "cg_metrivc" {
  name           = "instance_policy_filter"
  log_group_name = "/cg/ssm/logs"
  pattern        = "{ ($.eventSource = \"ssm.amazonaws.com\") && ($.eventName = \"StartSession\") && ($.awsRegion = \"ap-northeast-2\") }"

  metric_transformation {
    name      = "cg-metric"
    namespace = "cg-metric"
    value     = "1"
  }
}
