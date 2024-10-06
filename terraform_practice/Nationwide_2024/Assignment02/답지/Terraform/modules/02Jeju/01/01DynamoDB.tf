resource "aws_dynamodb_table" "user_table" {
  name           = "serverless-user-table"
  hash_key       = "id"
  billing_mode   = "PAY_PER_REQUEST"
  attribute {
    name = "id"
    type = "S"
  }
  tags = {
    Name = "serverless-user-table"
  }
}