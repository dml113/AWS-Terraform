resource "aws_ecr_repository" "wsc2024_repositories" {
  name                 = "wsc2024-ecr"
  image_tag_mutability = "MUTABLE"
}