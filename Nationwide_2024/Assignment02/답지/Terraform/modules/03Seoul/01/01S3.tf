resource "random_string" "random_name" {
  length  = 4
  special = false
  upper   = false
  number  = false 
}

# S3 버킷 생성
resource "aws_s3_bucket" "my_bucket" {
  bucket = "wsi-static-${random_string.random_name.result}" # 고유한 버킷 이름으로 변경
  acl    = "private"
}

resource "aws_s3_bucket_object" "upload_files"{
  bucket = aws_s3_bucket.my_bucket.id
  key    = "index.html"
  source = "./files/03Seoul/static/index.html"
}

resource "aws_s3_bucket_object" "upload_image1_files"{
  bucket = aws_s3_bucket.my_bucket.id
  key    = "/images/glass.jpg"
  source = "./files/03Seoul/static/images/glass.jpg"
}

resource "aws_s3_bucket_object" "upload_image2_files"{
  bucket = aws_s3_bucket.my_bucket.id
  key    = "/images/hamster.jpg"
  source = "./files/03Seoul/static/images/hamster.jpg"
}

resource "aws_s3_bucket_object" "upload_image3_files"{
  bucket = aws_s3_bucket.my_bucket.id
  key    = "/images/library.jpg"
  source = "./files/03Seoul/static/images/library.jpg"
}

resource "null_resource" "delete_bucket" {
  provisioner "local-exec" {
    command = "aws s3api put-object --bucket ${aws_s3_bucket.my_bucket.bucket} --key dev/ --content-length 0"
  }
  depends_on = [
    aws_s3_bucket_policy.my_bucket_policy
   ]
}