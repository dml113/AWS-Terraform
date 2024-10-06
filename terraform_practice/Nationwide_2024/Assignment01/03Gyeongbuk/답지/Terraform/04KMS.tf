resource "aws_kms_key" "dynamodb_kms" {
  description = "KMS key for encrypting DynamoDB table data"
  enable_key_rotation = true

  tags = {
    Name = "kms-dynamodb"
  }
}

resource "aws_kms_alias" "dynamodb_kms_alias" {
  name          = "alias/dynamodb-kms-key"
  target_key_id = aws_kms_key.dynamodb_kms.id
}

resource "aws_kms_key" "rds_kms" {
  description = "KMS key for encrypting RDS data"
  enable_key_rotation = true

  tags = {
    Name = "kms-rds"
  }
}

resource "aws_kms_alias" "rds_kms_alias" {
  name          = "alias/rds-kms-key"
  target_key_id = aws_kms_key.rds_kms.id
}

resource "aws_kms_key" "s3_kms" {
  description         = "KMS key for encrypting S3"
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-default-1"
    Statement = [
      {
        Sid       = "Enable IAM User Permissions"
        Effect    = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid       = "Allow CloudFront to use the key"
        Effect    = "Allow"
        Principal = {
          AWS = "arn:aws:iam::856369053181:role/OriginAccessControlRole"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "kms-s3"
  }
}

resource "aws_kms_alias" "s3_kms_alias" {
  name          = "alias/s3-kms-key"
  target_key_id = aws_kms_key.s3_kms.id
}

resource "aws_kms_key" "log_goups_kms" {
  description         = "KMS key for encrypting log-groups"
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "key-default-1",
    Statement = [
      {
        Sid       = "Enable IAM User Permissions",
        Effect    = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*",
        Resource = "*"
      },
      {
        Effect    = "Allow",
        Principal = {
          Service = "logs.${var.region}.amazonaws.com"
        },
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ],
        Resource = "*",
        Condition = {
          ArnEquals = {
            "kms:EncryptionContext:aws:logs:arn": "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:*"
          }
        }
      }
    ]
  })

  tags = {
    Name = "kms-log-groups"
  }
}

resource "aws_kms_alias" "log_groups_kms_alias" {
  name          = "alias/log-groups-kms-key"
  target_key_id = aws_kms_key.log_goups_kms.id
}
