################################################################################################################################################
#                                                                 VPC                                                                          #
################################################################################################################################################

module "managed_vpc" {
  source     = "./modules/vpc"
  vpc_name   = "managed-vpc"
  vpc_cidr   = "10.0.0.0/16"
  create_igw = true

  subnets = {
    "public-subnet-a" = { name = "public-subnet-a", cidr = "10.0.0.0/24", az = "ap-northeast-2a", public = true }
    "public-subnet-b" = { name = "public-subnet-b", cidr = "10.0.1.0/24", az = "ap-northeast-2b", public = true }
  }

  route_tables = {
    "public-rt" = "public-rt"
  }

  routes = [
    { 
      rt_name = "public-rt" 
      destination_cidr = "0.0.0.0/0"
      gateway_id = module.managed_vpc.igw_id 
    },
    { 
      rt_name = "public-rt" 
      destination_cidr = "192.168.0.0/16" 
      gateway_id = aws_ec2_transit_gateway.my-tgw.id 
    },
    { 
      rt_name = "public-rt" 
      destination_cidr = "172.16.0.0/16"
      gateway_id = aws_ec2_transit_gateway.my-tgw.id 
    }
  ]

  subnet_associations = {
    "public-subnet-a" = { subnet_key = "public-subnet-a", route_table_key = "public-rt" }
    "public-subnet-b" = { subnet_key = "public-subnet-b", route_table_key = "public-rt" }
  }
}

module "application_vpc" {
  source     = "./modules/vpc"
  vpc_name   = "application-vpc"
  vpc_cidr   = "172.16.0.0/16"
  create_igw = false

  subnets = {
    "app-subnet-a" = { name = "app-subnet-a", cidr = "172.16.0.0/24", az = "ap-northeast-2a", public = false }
    "app-subnet-b" = { name = "app-subnet-b", cidr = "172.16.1.0/24", az = "ap-northeast-2b", public = false }
  }

  route_tables = {
    "app-rt-a" = "app-rt-a"
    "app-rt-b" = "app-rt-b"
  }

  routes = [
    { 
      rt_name = "app-rt-a" 
      destination_cidr = "0.0.0.0/0"
      gateway_id = aws_ec2_transit_gateway.my-tgw.id 
    },
    {
      rt_name = "app-rt-b" 
      destination_cidr = "0.0.0.0/0"
      gateway_id = aws_ec2_transit_gateway.my-tgw.id 
    }
  ]

  subnet_associations = {
    "app-subnet-a" = { subnet_key = "app-subnet-a", route_table_key = "app-rt-a" }
    "app-subnet-b" = { subnet_key = "app-subnet-b", route_table_key = "app-rt-b" }
  }
}

module "database_vpc" {
  source     = "./modules/vpc"
  vpc_name   = "database-vpc"
  vpc_cidr   = "192.168.0.0/16"
  create_igw = false

  subnets = {
    "db-subnet-a" = { name = "db-subnet-a", cidr = "192.168.0.0/24", az = "ap-northeast-2a", public = false }
    "db-subnet-b" = { name = "db-subnet-b", cidr = "192.168.1.0/24", az = "ap-northeast-2b", public = false }
  }

  route_tables = {
    "db-rt-a" = "db-rt-a"
    "db-rt-b" = "db-rt-b"
  }

  routes = [
    { 
      rt_name = "db-rt-a" 
      destination_cidr = "0.0.0.0/0"
      gateway_id = aws_ec2_transit_gateway.my-tgw.id 
    },
    {
      rt_name = "db-rt-b" 
      destination_cidr = "0.0.0.0/0"
      gateway_id = aws_ec2_transit_gateway.my-tgw.id 
    }
  ]

  subnet_associations = {
    "db-subnet-a" = { subnet_key = "db-subnet-a", route_table_key = "db-rt-a" }
    "db-subnet-b" = { subnet_key = "db-subnet-b", route_table_key = "db-rt-b" }
  }

  # VPC endpoints are not created in this example
  # ‼️‼️‼️ 주의사항 ‼️‼️‼️
  # 아래 ENDPOINT는 default Security Group을 사용하므로 Inbound 수정해야 함.

  # vpc_endpoints = {
  #   "s3-endpoint" = { 
  #     service_name     = "com.amazonaws.ap-northeast-2.s3" 
  #     route_table_keys = ["public-rt", "app-rt-a", "app-rt-b"]
  #   }
  #   "dynamodb-endpoint" = { 
  #     service_name     = "com.amazonaws.ap-northeast-2.dynamodb"
  #     route_table_keys = ["public-rt", "app-rt-a", "app-rt-b"]
  #   }
  #   "ec2-endpoint" = {
  #     service_name  = "com.amazonaws.ap-northeast-2.ec2"
  #     type          = "Interface"
  #     subnet_keys   = ["app-subnet-a", "app-subnet-b"]
  #   }
  # }
}

