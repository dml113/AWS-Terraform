provider "aws" {
    region = var.region
}

data "aws_caller_identity" "current" {}

resource "random_integer" "random_number" {
  min = 100
  max = 99999
}
