resource "aws_iam_user" "admin_user" {
  name = "Admin2"
  tags = {
    "Name" = "Admin2"
  }
}

# IAM 사용자 콘솔 암호 설정
resource "aws_iam_user_login_profile" "admin_passwd" {
  user                    = aws_iam_user.admin_user.name
  password_reset_required = false
}

# 생성된 암호를 파일에 저장
resource "local_file" "admin_user_password_file" {
  filename = "admin_password.txt"  # 파일명을 원하는 대로 변경하세요
  content  = aws_iam_user_login_profile.admin_passwd.password
}

# CodeCommit에 대한 HTTPS Git 자격 증명 발급
resource "aws_iam_service_specific_credential" "admin_codecommit_credential" {
  user_name        = aws_iam_user.admin_user.name
  service_name     = "codecommit.amazonaws.com"
}

# 자격 증명을 파일에 저장
resource "local_file" "admin_codecommit_credential_file" {
  filename = "${path.module}/admin_codecommit_credential.txt"  # 파일명을 원하는 대로 변경하세요
  content  = <<EOF
Username: ${aws_iam_service_specific_credential.admin_codecommit_credential.service_user_name}
Password: ${aws_iam_service_specific_credential.admin_codecommit_credential.service_password}
EOF
}

resource "aws_iam_policy" "admin_user_policy" {
  name        = "admin_user-policy"
  description = "An user1 IAM policy"

  # 정책 문서
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "*",
            "Resource": "*"
        }
    ]
}

EOF
}

# 위에서 정의한 IAM 정책을 사용자에게 연결
resource "aws_iam_user_policy_attachment" "user_policy_attachment" {
  user       = aws_iam_user.admin_user.name
  policy_arn = aws_iam_policy.admin_user_policy.arn
}