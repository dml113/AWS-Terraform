resource "aws_s3_bucket" "bucket" {

  bucket   = "wsi-${random_string.random_name.result}" 
  tags = {
    Name = "wsi-${random_string.random_name.result}"
  }
}