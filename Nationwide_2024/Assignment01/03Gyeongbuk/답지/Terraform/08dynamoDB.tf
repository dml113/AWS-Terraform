resource "aws_dynamodb_table" "order_table" {
  name           = "order"
  hash_key       = "id"
  billing_mode   = "PROVISIONED"

  read_capacity  = 1
  write_capacity = 1

  attribute {
    name = "id"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb_kms.arn
  }

  tags = {
    Name = "order"
  }
}
