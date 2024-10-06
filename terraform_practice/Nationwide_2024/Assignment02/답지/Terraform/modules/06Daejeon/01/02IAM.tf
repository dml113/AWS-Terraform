data "aws_iam_policy_document" "document" {
  depends_on = [aws_dynamodb_table.table]
  statement {
    sid = "dynamodbtablepolicy"

    actions = [
      "dynamodb:PutItem",
      "dynamodb:Query",
      "dynamodb:GetItem",
      "dynamodb:DeleteItem"
    ]

    resources = [
      aws_dynamodb_table.table.arn
    ]
  }
}

resource "aws_iam_role" "role" {
  name               = "apigw_role"
  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "apigateway.amazonaws.com"
        },
        "Effect": "Allow"
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy" "policy" {
  name = "example_policy"
  role = aws_iam_role.role.id
  policy = data.aws_iam_policy_document.document.json
}