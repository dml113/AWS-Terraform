# 생성할 S3 버킷 이름에 사용할 랜덤 문자열 생성을 위한 리소스
resource "random_pet" "bucket_name" {
  length = 1
  separator = "-"
}

# S3 버킷 이름에 사용할 랜덤 문자열 생성을 위한 리소스
resource "random_string" "random_name" {
  length  = 7
  special = false
  upper   = false
  number  = false 
}

# 원본 S3 버킷 생성
resource "aws_s3_bucket" "original_bucket" {
  bucket = "j-s3-bucket-${random_string.random_name.result}-original"

  versioning {
    enabled = true  # 버전 관리 활성화
  }
}

# 원본 S3 버킷에 폴더 생성
resource "aws_s3_bucket_object" "original_folder" {
  bucket  = aws_s3_bucket.original_bucket.id  
  key     = "2024/"  # 폴더 이름
  content = ""  # 폴더를 비어있는 객체로 만듦
}

# 백업 S3 버킷 생성
resource "aws_s3_bucket" "backup_bucket" {
  bucket = "j-s3-bucket-${random_string.random_name.result}-backup"

  versioning {
    enabled = true  # 버전 관리 활성화
  }
}

# 백업 S3 버킷에 폴더 생성
resource "aws_s3_bucket_object" "backup_folder" {
  bucket  = aws_s3_bucket.backup_bucket.id  
  key     = "2024/"  # 폴더 이름
  content = ""  # 폴더를 비어있는 객체로 만듦
}

# 복제 역할을 위한 IAM 역할 생성
resource "aws_iam_role" "replication_role" {
  name = "s3-replication-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = {
        Service = "s3.amazonaws.com"
      },
      Action    = "sts:AssumeRole"
    }]
  })
}

# 복제 역할에 대한 정책 생성
resource "aws_iam_role_policy" "replication_role_policy" {
  name   = "s3-replication-role-policy"
  role   = aws_iam_role.replication_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = [
          "s3:ListBucket",
          "s3:GetReplicationConfiguration",
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging",
          "s3:GetObjectRetention",
          "s3:GetObjectLegalHold"
        ],
        Effect   = "Allow",
        Resource = [
          "arn:aws:s3:::j-s3-bucket-${random_string.random_name.result}-original",
          "arn:aws:s3:::j-s3-bucket-${random_string.random_name.result}-original/*",
          "arn:aws:s3:::j-s3-bucket-${random_string.random_name.result}-backup",
          "arn:aws:s3:::j-s3-bucket-${random_string.random_name.result}-backup/*"
        ]
      },
      {
        Action   = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags",
          "s3:ObjectOwnerOverrideToBucketOwner"
        ],
        Effect   = "Allow",
        Resource = [
          "arn:aws:s3:::j-s3-bucket-${random_string.random_name.result}-original/*",
          "arn:aws:s3:::j-s3-bucket-${random_string.random_name.result}-backup/*"
        ]
      }
    ]
  })
}

# S3 복제 구성 생성
resource "aws_s3_bucket_replication_configuration" "copy_replica" {
  role   = aws_iam_role.replication_role.arn
  bucket = aws_s3_bucket.original_bucket.bucket

  rule {
    id = "CopyReplica"

    filter {
      prefix = "2024/"  # 복제할 객체의 접두사
    }

    status = "Enabled"

    delete_marker_replication {
      status = "Disabled"
    }

    destination {
      bucket = aws_s3_bucket.backup_bucket.arn  # 대상 버킷 ARN
    }
  }
}

# 백업 버킷에 대한 S3 이벤트 알림 구성
resource "aws_s3_bucket_notification" "event_notification" {
  bucket = aws_s3_bucket.backup_bucket.bucket

  queue {
    queue_arn     = aws_sqs_queue.J_company_queue.arn
    events        = ["s3:ObjectCreated:*"]  # 객체 생성 이벤트
    filter_prefix = "2024/"  # 필터 접두사
  }
}
