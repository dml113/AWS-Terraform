resource "aws_iam_policy" "secrets_manager_policy" {
  name        = "ex-sm-ap-policy"
  description = "Policy allowing access to Secrets Manager secrets."

  # JSON policy document
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:ListSecretVersionIds"
        ],
        Resource = "arn:aws:secretsmanager:ap-northeast-2:${data.aws_caller_identity.current.account_id}:secret:*",
        Effect   = "Allow"
      }
    ]
  })
}