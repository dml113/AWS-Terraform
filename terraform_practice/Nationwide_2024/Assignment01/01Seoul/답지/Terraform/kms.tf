resource "aws_kms_key" "kubernetes" {
  provider = aws.ap
  description = "Kubernetes KMS key"

  tags = {
    Name = "Kubernetes"
  }
}

resource "aws_kms_alias" "kubernetes" {
  provider = aws.ap
  name          = "alias/Kubernetes"
  target_key_id  = aws_kms_key.kubernetes.key_id
}

resource "aws_kms_key" "ap" {
  provider = aws.ap
  description = "ap KMS key"

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-ap-1"
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
    Name = "ap_s33"
  }
}

resource "aws_kms_alias" "ap" {
  provider = aws.ap
  name          = "alias/ap_s33"
  target_key_id  = aws_kms_key.ap.key_id
}

resource "aws_kms_key" "us" {
  provider = aws.us
  description = "us KMS key"

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-us-1"
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
    Name = "us_s33"
  }
}

resource "aws_kms_alias" "us" {
  provider = aws.us
  name          = "alias/us_s33"
  target_key_id  = aws_kms_key.us.key_id
}


output "kube_kms_key_arn" {
  value = aws_kms_key.kubernetes.arn
}

output "ap_kms_key_arn" {
  value =  aws_kms_key.ap.arn
}

output "us_kms_key_arn" {
  value =  aws_kms_key.us.arn
}