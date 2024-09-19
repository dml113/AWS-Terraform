#
# Create VPC 
#
  resource "aws_vpc" "wsc2024-storage-vpc" {
  cidr_block = "192.168.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "wsc2024-storage-vpc"
  }
 }
 
#
# Create Public_Subnet 
#
  resource "aws_subnet" "wsc2024-storage-db-sn-a" {
  vpc_id     = aws_vpc.wsc2024-storage-vpc.id
  cidr_block = "192.168.0.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "wsc2024-storage-db-sn-a"
  }
 }

  resource "aws_subnet" "wsc2024-storage-db-sn-b" {
  vpc_id     = aws_vpc.wsc2024-storage-vpc.id
  cidr_block = "192.168.1.0/24"
  availability_zone = "us-east-1b"
 
  tags = {
    Name = "wsc2024-storage-db-sn-b"
  }
 }
 
#
# Create db_Route_Table
#
  resource "aws_route_table" "wsc2024-storage-db-rt-a" {
  vpc_id     = aws_vpc.wsc2024-storage-vpc.id
  
  tags = {
    Name = "wsc2024-storage-db-rt-a"
  }
 }

resource "aws_route" "storage_db_a_route1" {
  route_table_id = aws_route_table.wsc2024-storage-db-rt-a.id 
  destination_cidr_block = "10.0.0.0/16"
  transit_gateway_id = aws_ec2_transit_gateway.wsc2024-vpc-tgw.id 
}

resource "aws_route" "storage_db_a_route2" {
  route_table_id = aws_route_table.wsc2024-storage-db-rt-a.id 
  destination_cidr_block = "172.16.0.0/16"
  transit_gateway_id = aws_ec2_transit_gateway.wsc2024-vpc-tgw.id 
}

  resource "aws_route_table_association" "wsc2024-storage-db_association_a" {
  subnet_id      = aws_subnet.wsc2024-storage-db-sn-a.id
  route_table_id = aws_route_table.wsc2024-storage-db-rt-a.id
}

  resource "aws_route_table" "wsc2024-storage-db-rt-b" {
  vpc_id     = aws_vpc.wsc2024-storage-vpc.id
  
  tags = {
    Name = "wsc2024-storage-db-rt-b"
  }
 }

resource "aws_route" "storage_db_b_route1" {
  route_table_id = aws_route_table.wsc2024-storage-db-rt-b.id 
  destination_cidr_block = "10.0.0.0/16"
  transit_gateway_id = aws_ec2_transit_gateway.wsc2024-vpc-tgw.id 
}

resource "aws_route" "storage_db_b_route2" {
  route_table_id = aws_route_table.wsc2024-storage-db-rt-b.id 
  destination_cidr_block = "172.16.0.0/16"
  transit_gateway_id = aws_ec2_transit_gateway.wsc2024-vpc-tgw.id 
}

  resource "aws_route_table_association" "wsc2024-storage-db_association_b" {
  subnet_id      = aws_subnet.wsc2024-storage-db-sn-b.id
  route_table_id = aws_route_table.wsc2024-storage-db-rt-b.id
}