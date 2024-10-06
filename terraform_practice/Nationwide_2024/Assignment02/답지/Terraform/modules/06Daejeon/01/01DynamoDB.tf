resource "aws_dynamodb_table" "table" {
  name           = "wsi-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "name"

  attribute {
    name = "name"
    type = "S"
  }
}