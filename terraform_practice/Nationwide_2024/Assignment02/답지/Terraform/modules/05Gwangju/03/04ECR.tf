locals {
  repository_names = ["service"]
}
resource "aws_ecr_repository" "customer_repositories" {
  count                = length(local.repository_names)
  name                 = local.repository_names[count.index]
  image_tag_mutability = "IMMUTABLE"
}

resource "aws_ecr_repository_policy" "customer_repositories_policy" {
  count      = length(local.repository_names)
  repository = aws_ecr_repository.customer_repositories[count.index].name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid       = "ScanOnPush",
      Effect    = "Allow",
      Principal = "*",
      Action    = "ecr:PutImage",
      Condition = {
        StringEquals = {
          "aws:SourceTag" = "*"
        }
      }
    }]
  })
}