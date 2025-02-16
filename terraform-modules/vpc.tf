module "vpc" {
    source  = "terraform-aws-modules/vpc/aws"

    name            = "my-vpc"
    cidr            = "10.0.0.0/16"

    azs             = ["ap-northeast-2a", "ap-northeast-2b"]

    public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
    public_subnet_names = ["my-public-subnet-a, my-public-subnet-b"]

    private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]
    private_subnet_names = ["my-private-subnet-a, my-private-subnet-b"]

    database_subnets = ["10.0.5.0/24", "10.0.6.0/24"]
    database_subnet_names = ["my-db-subnet-a, my-db-subnet-b"]

    create_database_subnet_group = true
    create_database_subnet_route_table = true

    enable_nat_gateway = true
    single_nat_gateway = false
    one_nat_gateway_per_az = true

    enable_dns_hostnames = true
    enable_dns_support   = true
}