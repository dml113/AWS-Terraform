resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.my_vpc.id
  service_name = "com.amazonaws.ap-northeast-2.s3"
  route_table_ids = [aws_route_table.private_route_table1.id]

  tags = {
    Name = "s3-endpoint"
  }
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id       = aws_vpc.my_vpc.id
  service_name = "com.amazonaws.ap-northeast-2.dynamodb"
  route_table_ids = [aws_route_table.private_route_table1.id]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem"
      ],
      "Resource": "arn:aws:dynamodb:ap-northeast-2:${data.aws_caller_identity.current.account_id}:table/gm-db"
    }
  ]
}
POLICY

  tags = {
    Name = "dynamodb-endpoint"
  }
}
