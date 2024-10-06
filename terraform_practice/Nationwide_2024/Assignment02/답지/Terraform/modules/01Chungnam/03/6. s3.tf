resource "aws_s3_bucket" "bucket" {
  bucket = "gm-${random_integer.random_number.result}"

  acl    = "private"

  tags = {
    Name = "gm-${random_integer.random_number.result}"  # 변경 
  }
}

resource "aws_s3_bucket_object" "application_upload" {
  bucket  = aws_s3_bucket.bucket.id
  key     = "app.py"
  source  = "./files/01Chungnam/application/app.py"
}

resource "aws_s3_bucket_object" "html_upload" {
  bucket  = aws_s3_bucket.bucket.id
  key     = "index.html"
  source  = "./files/01Chungnam/application/index.html"
}