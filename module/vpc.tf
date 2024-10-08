# VPC
module "VPC" {
  source                   = "./modules/VPC"
  availability_zones       = ["ap-northeast-2a", "ap-northeast-2b"]
  vpc_name                 = "vpc"
  vpc_cidr                 = "10.0.0.0/16"

  public_subnets_cidr      = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnet_names      = ["public-sn-a", "public-sn-b"]
  public_route_table_name  = "public-rt"

  private_subnets_cidr     = ["10.0.3.0/24", "10.0.4.0/24"]
  private_subnet_names     = ["private-sn-a", "private-sn-b"]
  private_route_table_names = ["private-rt-a", "private-rt-b"]

  # data_subnets_cidr        = ["10.0.5.0/24", "10.0.6.0/24"]
  # data_subnet_names        = ["data-sn-a", "data-sn-b"]
  # data_route_table_names   = ["data-rt-a", "data-rt-b"]

  igw_name                 = "igw"
  nat_eip_names            = ["eip-a", "eip-b"]
  nat_gw_names             = ["natgw-a", "natgw-b"]
}