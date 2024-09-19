resource "random_pet" "bucket_name" {
  length = 4
  separator = "-"
}

resource "aws_s3_bucket" "bucket" {
    bucket = "${random_pet.bucket_name.id}-gmst-uploadfile"
}

resource "aws_s3_bucket_object" "product_upload" {
  bucket  = aws_s3_bucket.bucket.id
  key     = "/configmap.yml"
  source  = "./files/06Daejeon/03/manifest/configmap.yml"
}

resource "null_resource" "previous" {}

resource "time_sleep" "wait_500_seconds" {
  depends_on = [null_resource.previous]

  create_duration = "500s"
}

resource "null_resource" "empty_bucket" {
  provisioner "local-exec" {
    command = "aws s3 rm s3://${aws_s3_bucket.bucket.id} --recursive"
  }

  triggers = {
    always_run = "${timestamp()}"
  }
  depends_on = [
    time_sleep.wait_500_seconds
  ]
}

resource "null_resource" "delete_bucket" {
  provisioner "local-exec" {
    command = "aws s3api delete-bucket --bucket ${aws_s3_bucket.bucket.id}"
  }
  depends_on = [
    null_resource.empty_bucket
  ]
}