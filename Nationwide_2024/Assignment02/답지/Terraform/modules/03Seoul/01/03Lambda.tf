# IAM 역할 생성
resource "aws_iam_role" "lambda_role" {
  name = "lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Administrator 권한 정책 첨부
resource "aws_iam_role_policy_attachment" "lambda_role_admin_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Lambda 함수 생성
resource "aws_lambda_function" "wsi_resizing_function" {
  function_name = "wsi-resizing-function"
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_role.arn
  timeout       = 30

  # Lambda 함수 코드 업로드
  filename         = "./Reference/03Seoul/01/lambda/test.zip"
}