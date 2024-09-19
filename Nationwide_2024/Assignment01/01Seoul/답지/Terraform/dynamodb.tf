resource "aws_kms_key" "dynamodb_kms_key" {
provider = aws.ap
description = "KMS key for DynamoDB table encryption"
enable_key_rotation = true
}

resource "aws_kms_alias" "dynamodb_kms_alias" {
provider = aws.ap
name          = "alias/dynamodb_kms_key"
target_key_id = aws_kms_key.dynamodb_kms_key.id
}

resource "aws_dynamodb_table" "order" {
  provider = aws.ap
  name           = "order"
  billing_mode   = "PAY_PER_REQUEST"

  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }


  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb_kms_key.arn
  }
}

