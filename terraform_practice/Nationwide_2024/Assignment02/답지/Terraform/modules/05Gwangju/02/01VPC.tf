#
# Create VPC 

  resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "warm-vpc"
  }
 }

#
# Create Public_Subnet 
#
  resource "aws_subnet" "public_subnet_a" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "${var.region}a"
 
  map_public_ip_on_launch = true

  tags = {
    Name = "warm-pub-sn-a"
  }
 }

  resource "aws_subnet" "public_subnet_b" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "${var.region}b"
 
  map_public_ip_on_launch = true

  tags = {
    Name = "warm-pub-sn-b"
  }
 }
 
#
# Create private-subnet 
#
  resource "aws_subnet" "private_subnet_a" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "${var.region}a"

  tags = {
    Name = "warm-priv-sn-a"
  }
 }

  resource "aws_subnet" "private_subnet_b" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "${var.region}b"

  tags = {
    Name = "warm-priv-sn-b"
  }
 }

#
# Create Internet_Gateway 
#
  resource "aws_internet_gateway" "igw" {
  vpc_id     = aws_vpc.vpc.id
  
  tags = {
    Name = "warm-igw"
  }
 }

#
# Create EIP
#
  resource "aws_eip" "eip_a" {
  domain   = "vpc"

  tags = {
    Name = "warm-eip-a"
  }
 }

  resource "aws_eip" "eip_b" {
  domain   = "vpc"

  tags = {
    Name = "warm-eip-b"
  }
 }

#
# Create Nat_Gateway
#
  resource "aws_nat_gateway" "natgw_a" {
  allocation_id = aws_eip.eip_a.id
  subnet_id     = aws_subnet.public_subnet_a.id
  
  tags = {
    Name = "warm-natgw-a"
  }
 }

  resource "aws_nat_gateway" "natgw_b" {
  allocation_id = aws_eip.eip_b.id
  subnet_id     = aws_subnet.public_subnet_b.id
  
  tags = {
    Name = "warm-natgw-b"
  }
 }

#
# Create Public_Route_Table
#
  resource "aws_route_table" "public_rt" {
  vpc_id     = aws_vpc.vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  
  tags = {
    Name = "warm-pub-rt"
  }
 }

  resource "aws_route_table_association" "public_association_a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_rt.id
}

  resource "aws_route_table_association" "public_association_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_rt.id
}

#
# Create Private_Route_Table
#
  resource "aws_route_table" "private_rt_a" {
  vpc_id     = aws_vpc.vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.natgw_a.id
  }
  
  tags = {
    Name = "warm-priv-a-rt"
  }
 }

  resource "aws_route_table_association" "private_association_a" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private_rt_a.id
}

  resource "aws_route_table" "private_rt_b" {
  vpc_id     = aws_vpc.vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.natgw_b.id
  }
  
  tags = {
    Name = "warm-priv-b-rt"
  }
 }

 resource "aws_route_table_association" "private_association_b" {
  subnet_id      = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.private_rt_b.id
}