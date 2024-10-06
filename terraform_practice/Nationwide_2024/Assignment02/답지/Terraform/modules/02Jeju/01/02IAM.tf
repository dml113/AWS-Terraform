# IAM 역할 생성
resource "aws_iam_role" "APIGatewayDynamoDBRole" {
  name = "APIGatewayDynamoDBRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = ["apigateway.amazonaws.com"]
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# DynamoDB 권한 정책 첨부
resource "aws_iam_role_policy" "APIGatewayDynamoDBPolicy" {
  name   = "APIGatewayDynamoDBPolicy"
  role   = aws_iam_role.APIGatewayDynamoDBRole.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement: [
      {
        Sid: "VisualEditor0",
        Effect: "Allow",
        Action: [
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:GetItem"
        ],
        Resource: "arn:aws:dynamodb:*:*:table/serverless-user-table"
      }
    ]
  })
}