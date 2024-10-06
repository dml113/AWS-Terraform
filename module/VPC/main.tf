terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

module "VPC" {
  source                   = "./modules/VPC"
  vpc_name                 = "vpc"
  vpc_cidr                 = "10.0.0.0/16"
  public_subnets_cidr      = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets_cidr     = ["10.0.3.0/24", "10.0.4.0/24"]
  data_subnets_cidr        = ["10.0.5.0/24", "10.0.6.0/24"]
  availability_zones       = ["ap-northeast-2a", "ap-northeast-2b"]
  public_subnet_names      = ["public-sn-a", "public-sn-b"]
  private_subnet_names     = ["private-sn-a", "private-sn-b"]
  igw_name                 = "igw"
  nat_eip_names            = ["eip-a", "eip-b"]
  nat_gw_names             = ["natgw-a", "natgw-b"]
  public_route_table_name  = "public-rt"
  private_route_table_names = ["private-rt-a", "private-rt-b"]
}