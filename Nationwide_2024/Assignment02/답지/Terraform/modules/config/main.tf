# AWS Config 역할 설정
resource "aws_iam_role" "aws_config_role" {
  name = "aws_config_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "config.amazonaws.com"
      }
    }]
  })

  inline_policy {
    name = "allow_ec2_and_logs"
    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Effect = "Allow",
          Action = "*",
          Resource = "*"
        }
      ]
    })
  }
}

resource "random_pet" "bucket_name" {
  length = 4
  separator = "-"
}

# S3 버킷 설정
resource "aws_s3_bucket" "config_bucket" {
  bucket = "${random_pet.bucket_name.id}-bucket"
  acl    = "private"
}

# AWS Config 레코더 설정
resource "aws_config_configuration_recorder" "config_recorder" {
  name     = "wsi-config-recorder"
  role_arn = aws_iam_role.aws_config_role.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

# AWS Config 전송 채널 설정
resource "aws_config_delivery_channel" "config_delivery_channel" {
  name           = "wsi-config-delivery-channel"
  s3_bucket_name = aws_s3_bucket.config_bucket.bucket

  depends_on = [
    aws_config_configuration_recorder.config_recorder
  ]
}

# AWS Config 레코더 시작 (프로비저닝 후)
resource "null_resource" "start_config_recorder" {
  provisioner "local-exec" {
    command = "aws configservice start-configuration-recorder --configuration-recorder-name ${aws_config_configuration_recorder.config_recorder.name}"
  }

  triggers = {
    config_recorder_id = aws_config_configuration_recorder.config_recorder.id
  }

  depends_on = [
    aws_config_configuration_recorder.config_recorder,
    aws_config_delivery_channel.config_delivery_channel
  ]
}