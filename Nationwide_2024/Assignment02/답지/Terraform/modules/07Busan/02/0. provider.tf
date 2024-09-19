terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region     = var.region
}

data "aws_availability_zones" "available" {}

resource "random_integer" "random_number" {
  min = 100
  max = 99999
}

data "aws_caller_identity" "current" {}