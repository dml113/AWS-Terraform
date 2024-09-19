resource "aws_ecr_repository" "my_repo" {
  name = "wsi-ecr"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "wsi-ecr"
  }
}