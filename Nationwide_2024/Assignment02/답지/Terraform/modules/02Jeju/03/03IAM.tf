resource "aws_iam_policy" "j_s3_policy" {
  name        = "bastion-policy-s3"
  description = "S3 access policy for specific buckets with restrictions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = [
          "arn:aws:s3:::j-s3-bucket-${random_string.random_name.result}-original/*",
          "arn:aws:s3:::j-s3-bucket-${random_string.random_name.result}-backup/*"
        ]
      },
      {
        Effect   = "Deny"
        Action   = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "arn:aws:s3:::j-s3-bucket-${random_string.random_name.result}-backup/*/*"
      }
    ]
  })
}

resource "aws_iam_policy" "j_sqs_policy" {
  name        = "bastion-policy-sqs"
  description = "SQS send message policy for specific queue"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "sqs:SendMessage"
        ]
        Resource = "arn:aws:sqs:ap-northeast-2:${data.aws_caller_identity.current.account_id}:J-company-sqs"
      }
    ]
  })
}

resource "aws_iam_role" "ec2_role" {
  name = "J-company-role-bastion"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

data "aws_iam_policy" "admin_policy" {
  arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.j_s3_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_sqs_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.j_sqs_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_admin_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = data.aws_iam_policy.admin_policy.arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "jeju-ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}