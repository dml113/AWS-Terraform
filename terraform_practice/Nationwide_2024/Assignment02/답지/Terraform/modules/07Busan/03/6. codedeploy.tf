# CodeDeploy 역할 및 정책
resource "aws_iam_role" "codedeploy_role" {
  name = "codedeploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "codedeploy_policy" {
  name = "codedeploy-policy"
  role = aws_iam_role.codedeploy_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "ec2:Describe*",
          "s3:Get*",
          "s3:List*",
          "autoscaling:Describe*",
          "autoscaling:UpdateAutoScalingGroup"
        ],
        Effect = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_codedeploy_app" "wsi_app" {
  name             = "wsi-app"
  compute_platform = "Server"
}

resource "aws_codedeploy_deployment_group" "wsi_app_deployment_group" {
  app_name              = aws_codedeploy_app.wsi_app.name
  deployment_group_name = "wsi-dg"
  service_role_arn      = aws_iam_role.codedeploy_role.arn

  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE" 
  }

  deployment_config_name = "CodeDeployDefault.OneAtATime"

  ec2_tag_filter {
    key   = "Name"
    value = "wsi-server"
    type  = "KEY_AND_VALUE"
  }
}
