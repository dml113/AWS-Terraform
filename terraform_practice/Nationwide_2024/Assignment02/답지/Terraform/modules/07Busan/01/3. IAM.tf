# IAM 사용자 생성
resource "aws_iam_user" "wsi_project_user1" {
  name = "wsi-project-user1"
}

# IAM 사용자 콘솔 암호 설정
resource "aws_iam_user_login_profile" "wsi_project_user1_login" {
  user                    = aws_iam_user.wsi_project_user1.name
  password_reset_required = false
}

# 생성된 암호를 파일에 저장
resource "local_file" "user1_password_file" {
  filename = "user1_password.txt"  # 파일명을 원하는 대로 변경하세요
  content  = aws_iam_user_login_profile.wsi_project_user1_login.password
}

# IAM 정책 정의
resource "aws_iam_policy" "user1_policy" {
  name        = "user1-policy"
  description = "An user1 IAM policy"

  # 정책 문서
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*",
        "ec2:CreateSecurityGroup",
        "ec2:DeleteSecurityGroup",
        "ec2:AuthorizeSecurityGroupIngress"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:RunInstances",
        "ec2:CreateTags"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Deny",
      "Action": "ec2:RunInstances",
      "Resource": "arn:aws:ec2:*:*:instance/*",
      "Condition": {
        "StringNotEquals": {
          "aws:RequestTag/wsi-project": "developer"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": "ec2:TerminateInstances",
      "Resource": "arn:aws:ec2:*:*:instance/*",
      "Condition": {
        "StringEquals": {
          "aws:ResourceTag/wsi-project": "developer",
          "aws:ResourceTag/CreatedBy": "$${aws:username}"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": "ec2:CreateSecurityGroup",
      "Resource": "*"
    }
  ]
}
EOF
}

# 위에서 정의한 IAM 정책을 사용자에게 연결
resource "aws_iam_user_policy_attachment" "user1_policy_attachment" {
  user       = aws_iam_user.wsi_project_user1.name
  policy_arn = aws_iam_policy.user1_policy.arn
}


###########################################################################


resource "aws_iam_user" "wsi-project-user2" {
  name = "wsi-project-user2"
}

resource "aws_iam_user_login_profile" "wsi-project-user2-login" {
  user                    = aws_iam_user.wsi-project-user2.name
  password_reset_required = false
}

resource "local_file" "user2_password_file" {
  filename = "user2_password.txt"
  content  = aws_iam_user_login_profile.wsi-project-user2-login.password
}

resource "aws_iam_policy" "ec2_delete_policy" {
  name        = "ec2-delete-policy"
  description = "Allows users to delete EC2 instances with { wsi-project: developer } tag"

  policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "ec2:DescribeInstances",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "ec2:TerminateInstances",
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "ec2:ResourceTag/wsi-project": "developer"
        }
      }
    }
  ]
})
}



resource "aws_iam_policy_attachment" "attach_ec2_delete_policy" {
  name       = "attach-ec2-delete-policy"
  policy_arn = aws_iam_policy.ec2_delete_policy.arn
  users      = [aws_iam_user.wsi-project-user2.name]
}

resource "aws_iam_user_policy_attachment" "user2_policy_attachment" {
  user       = aws_iam_user.wsi-project-user2.name
  policy_arn = aws_iam_policy.ec2_delete_policy.arn
}