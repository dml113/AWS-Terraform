module "vpc" {
    source  = "terraform-aws-modules/vpc/aws"

    name            = "iac-vpc"
    cidr            = "10.20.0.0/16"
    azs             = ["ap-northeast-2a", "ap-northeast-2c"]

    public_subnets  = ["10.20.100.0/24", "10.20.101.0/24"]
    public_subnet_names = ["iac-pub-sn-a" , "iac-pub-sn-c"]
    map_public_ip_on_launch = true

    private_subnets = ["10.20.102.0/24", "10.20.103.0/24"]
    private_subnet_names = ["iac-priv-sn-a" , "iac-priv-sn-c"]

    enable_nat_gateway = true
    single_nat_gateway = false
    one_nat_gateway_per_az = true

    enable_dns_hostnames = true
    enable_dns_support   = true
}