resource "aws_dynamodb_table" "order_table" {
  name           = "order"
  hash_key       = "id"
  billing_mode   = "PAY_PER_REQUEST"
  attribute {
    name = "id"
    type = "S"
  }
  tags = {
    Name = "order"
  }
}