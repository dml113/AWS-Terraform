terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-northeast-2"
  alias = "ap"
}
provider "aws" {
  region = "us-east-1"
  alias = "us"
}

data "aws_caller_identity" "current" {}