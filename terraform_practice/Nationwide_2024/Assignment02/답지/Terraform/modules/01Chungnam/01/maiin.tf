terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

######################################################################
#                                                                    #
#                             IAM - User                             #
#                                                                    #
######################################################################

resource "aws_iam_user" "Admin" {
  name = "Admin"
}

resource "aws_iam_user_policy_attachment" "admin_access" {
  user       = aws_iam_user.Admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_user" "Employee" {
  name = "Employee"
}

resource "aws_iam_user_policy_attachment" "employee_access" {
  user       = aws_iam_user.Employee.name
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
}

######################################################################
#                                                                    #
#                             IAM - Role                             #
#                                                                    #
######################################################################

resource "aws_iam_role" "ec2_role" {
  name               = "wsc2024-instance-role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

######################################################################
#                                                                    #
#                             CloudTrail                             #
#                                                                    #
######################################################################

# filter를 생성할 때 permmsion 오류가 뜨면 account id와 region을 확인한다.

resource "aws_cloudwatch_log_group" "cloudtrail_log_group" {
  name = "wsc2024-gvn-LG"
}

resource "aws_iam_role" "cloudtrail_role" {
  name               = "wsc2024-cloudtrail-role"
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
  name   = "wsc2024-cloudtrail-cloudwatch-policy"
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
  name                          = "wsc2024-CT"
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
  name = "wsc2024-gvn-Lambda-role"

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
  name        = "lambda_execution_policy"
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

resource "aws_lambda_function" "wsc2024_gvn_lambda" {
  function_name    = "wsc2024-gvn-Lambda"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  filename         = "./files/01Chungnam/lambda_function.zip"
  source_code_hash = filebase64sha256("./files/01Chungnam/lambda_function.zip")
  timeout          = 10

  environment {
    variables = {
      LOG_LEVEL = "INFO"
    }
  }
}

resource "aws_cloudwatch_log_group" "example" {
  name = "/aws/lambda/wsc2024-gvn-log-group"
}

resource "aws_cloudwatch_log_subscription_filter" "lambda_log_subscription_filter" {
  name            = "wsc2024-gvn-log-subscription-filter"
  log_group_name  = "wsc2024-gvn-LG"  # CloudWatch Log Group name
  filter_pattern  = "{ $.eventName = AttachRolePolicy && $.userIdentity.userName = Employee && $.requestParameters.roleName = wsc2024-instance-role }"
  destination_arn = aws_lambda_function.wsc2024_gvn_lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.wsc2024_gvn_lambda.function_name
  principal     = "logs.amazonaws.com"
  source_arn    = "arn:aws:logs:ap-northeast-2:${data.aws_caller_identity.current.account_id}:log-group:wsc2024-gvn-LG:*"  # region과 account id를 알아서 변경한다.
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "./files/01Chungnam/lambda_function.py"
  output_path = "./files/01Chungnam/lambda_function.zip"
}

######################################################################
#                                                                    #
#                          CloudWatch - Alarm                        #
#                                                                    #
######################################################################

# 기존에 생성된 CloudWatch Log Group의 이름
variable "log_group_name" {
  default = "wsc2024-gvn-LG"
}

# 지표 필터 생성
resource "aws_cloudwatch_log_metric_filter" "instance_policy_filter" {
  name           = "instance_policy_filter"
  log_group_name = var.log_group_name
  pattern        = "{ $.eventName = AttachRolePolicy && $.userIdentity.userName = Employee && $.requestParameters.roleName = wsc2024-instance-role}"

  metric_transformation {
    name      = "instance_role_policy"
    namespace = "CloudTrail"
    value     = "1"
    default_value = "0"
  }
}

# CloudWatch Alarm 생성
resource "aws_cloudwatch_metric_alarm" "wsc2024_gvn_alarm" {
  alarm_name          = "wsc2024-gvn-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.instance_policy_filter.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.instance_policy_filter.metric_transformation[0].namespace
  period              = 10
  statistic           = "Sum"
  threshold           = 1

  alarm_description   = "Alarm for instance role policy attachment"
}

######################################################################
#                                                                    #
#                          EC2 - bastion                             #
#                                                                    #
######################################################################

#
# Create Key-pair
#
resource "tls_private_key" "bastion_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "bastion_keypair" {
  key_name   = "01bastion-keypair.pem"
  public_key = tls_private_key.bastion_key.public_key_openssh
}

resource "local_file" "bastion_local" {
  filename = "01task1.pem"
  content  = tls_private_key.bastion_key.private_key_pem
}

#
# Create Security_Group
#
resource "aws_security_group" "Bastion_Instance_SG" {
  name        = "warm-bastion-ec2-sg"
  description = "warm-bastion-ec2-sg"
  vpc_id      = var.vpc_id

  tags = {
    Name = "warm-bastion-ec2-sg"
  }
}

#
# Create Security_Group_Rule
#
data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

resource "aws_security_group_rule" "Bastion_Instance_SG_ingress" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["${chomp(data.http.myip.body)}/32"]
  security_group_id = aws_security_group.Bastion_Instance_SG.id
}

resource "aws_security_group_rule" "Bastion_Instance_SG_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.Bastion_Instance_SG.id
}

#
# Create Bastion_Role
#
data "aws_iam_policy_document" "AdministratorAccessDocument" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy" "AdministratorAccess" {
  arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role" "bastion_role" {
  name               = "01warm-bastion-role"
  assume_role_policy = data.aws_iam_policy_document.AdministratorAccessDocument.json
}

resource "aws_iam_role_policy_attachment" "bastion_policy" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = data.aws_iam_policy.AdministratorAccess.arn
}

#
# Create Bastion_profile
#
resource "aws_iam_instance_profile" "bastion_profiles" {
  name = "01bastion_profiles_a"
  role = aws_iam_role.bastion_role.name
}

#
# Create Bastion_Instance
#
resource "aws_instance" "Bastion_Instance" {
  security_groups       = [aws_security_group.Bastion_Instance_SG.name] # 보안 그룹의 이름을 사용하여 연결
  ami                   = "ami-01123b84e2a4fba05"                       # Amazon Linux 2023
  iam_instance_profile  = aws_iam_instance_profile.bastion_profiles.name
  instance_type         = "t3.small"
  key_name              = "01bastion-keypair.pem"
  tags = {
    Name = "bastion-ec2"
  }
}