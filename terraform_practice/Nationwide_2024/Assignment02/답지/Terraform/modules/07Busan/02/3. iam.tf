# IAM 사용자 생성
resource "aws_iam_user" "wsi-project-user" {
  name = "wsi-project-user"
}

# IAM 사용자 콘솔 암호 설정
resource "aws_iam_user_login_profile" "wsi-project-user-login" {
  user                    = aws_iam_user.wsi-project-user.name
  password_reset_required = false
}

# 생성된 암호를 파일에 저장
resource "local_file" "user1_password_file" {
  filename = "user_password.txt"  # 파일명을 원하는 대로 변경하세요
  content  = aws_iam_user_login_profile.wsi-project-user-login.password
}

resource "aws_iam_user_policy_attachment" "wsi-project-user-admin-attachment" {
  user       = aws_iam_user.wsi-project-user.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}