resource "aws_ecr_repository" "customer" {
  provider = aws.ap
  name                 = "customer"
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  encryption_configuration {
    encryption_type = "KMS"
  }
}


resource "aws_ecr_repository" "product" {
  provider = aws.ap
  name                 = "product"
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  encryption_configuration {
    encryption_type = "KMS"
  }
}

resource "aws_ecr_repository" "order" {
  provider = aws.ap
  name                 = "order"
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  encryption_configuration {
    encryption_type = "KMS"
  }
}


resource "aws_ecr_replication_configuration" "example" {
  provider = aws.ap
  replication_configuration {
    rule {
      repository_filter {
        filter     = "customer"
        filter_type = "PREFIX_MATCH"
      }
      destination {
        region      = "us-east-1"
        registry_id = aws_ecr_repository.customer.registry_id
      }
    }
    rule {
      repository_filter {
        filter     = "product"
        filter_type = "PREFIX_MATCH"
      }
      destination {
        region      = "us-east-1"
        registry_id = aws_ecr_repository.product.registry_id
      }
    }
    rule {
      repository_filter {
        filter     = "order"
        filter_type = "PREFIX_MATCH"
      }
      destination {
        region      = "us-east-1"
        registry_id = aws_ecr_repository.order.registry_id
      }
    }
  }
}