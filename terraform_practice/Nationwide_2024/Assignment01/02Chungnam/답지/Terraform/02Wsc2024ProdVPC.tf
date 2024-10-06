#
# Create VPC 
#
  resource "aws_vpc" "wsc2024-prod-vpc" {
  cidr_block = "172.16.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "wsc2024-prod-vpc"
  }
 }

#
# Create Public_Subnet 
#
  resource "aws_subnet" "wsc2024-prod-load-sn-a" {
  vpc_id     = aws_vpc.wsc2024-prod-vpc.id
  cidr_block = "172.16.0.0/24"
  availability_zone = "us-east-1a"
 
  map_public_ip_on_launch = true

  tags = {
    Name = "wsc2024-prod-load-sn-a"
  }
 }

  resource "aws_subnet" "wsc2024-prod-load-sn-b" {
  vpc_id     = aws_vpc.wsc2024-prod-vpc.id
  cidr_block = "172.16.1.0/24"
  availability_zone = "us-east-1b"
 
  map_public_ip_on_launch = true

  tags = {
    Name = "wsc2024-prod-load-sn-b"
  }
 }
 
#
# Create private_subnet 
#
  resource "aws_subnet" "wsc2024-prod-app-sn-a" {
  vpc_id     = aws_vpc.wsc2024-prod-vpc.id
  cidr_block = "172.16.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "wsc2024-prod-app-sn-a"
  }
 }

  resource "aws_subnet" "wsc2024-prod-app-sn-b" {
  vpc_id     = aws_vpc.wsc2024-prod-vpc.id
  cidr_block = "172.16.3.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "wsc2024-prod-app-sn-b"
  }
 }

#
# Create Internet_Gateway 
#
  resource "aws_internet_gateway" "wsc2024-prod-igw" {
  vpc_id     = aws_vpc.wsc2024-prod-vpc.id
  
  tags = {
    Name = "wsc2024-prod-igw"
  }
 }

#
# Create EIP
#
  resource "aws_eip" "wsc2024-prod-eip_a" {
  domain   = "vpc"

  tags = {
    Name = "wsc2024-prod-eip-a"
  }
 }

  resource "aws_eip" "wsc2024-prod-eip_b" {
  domain   = "vpc"

  tags = {
    Name = "wsc2024-prod-eip-b"
  }
 }

#
# Create Nat_Gateway
#
  resource "aws_nat_gateway" "wsc2024-prod-natgw-a" {
  allocation_id = aws_eip.wsc2024-prod-eip_a.id
  subnet_id     = aws_subnet.wsc2024-prod-load-sn-a.id
  
  tags = {
    Name = "wsc2024-prod-natgw-a"
  }
 }

  resource "aws_nat_gateway" "wsc2024-prod-natgw-b" {
  allocation_id = aws_eip.wsc2024-prod-eip_b.id
  subnet_id     = aws_subnet.wsc2024-prod-load-sn-b.id
  
  tags = {
    Name = "wsc2024-prod-natgw-b"
  }
 }

#
# Create load_Route_Table
#
  resource "aws_route_table" "wsc2024-prod-load-rt" {
  vpc_id     = aws_vpc.wsc2024-prod-vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wsc2024-prod-igw.id
  }
  
  tags = {
    Name = "wsc2024-prod-load-rt"
  }
 }

resource "aws_route" "prod_load_route1" {
  route_table_id = aws_route_table.wsc2024-prod-load-rt.id 
  destination_cidr_block = "10.0.0.0/16"
  transit_gateway_id = aws_ec2_transit_gateway.wsc2024-vpc-tgw.id 
}

resource "aws_route" "prod_load_route2" {
  route_table_id = aws_route_table.wsc2024-prod-load-rt.id 
  destination_cidr_block = "192.168.0.0/16"
  transit_gateway_id = aws_ec2_transit_gateway.wsc2024-vpc-tgw.id 
}

  resource "aws_route_table_association" "wsc2024-prod-load_association_a" {
  subnet_id      = aws_subnet.wsc2024-prod-load-sn-a.id
  route_table_id = aws_route_table.wsc2024-prod-load-rt.id
}

  resource "aws_route_table_association" "wsc2024-prod-load_association_b" {
  subnet_id      = aws_subnet.wsc2024-prod-load-sn-b.id
  route_table_id = aws_route_table.wsc2024-prod-load-rt.id
}

#
# Create app_Route_Table
#
  resource "aws_route_table" "wsc2024-prod-app-rt-a" {
  vpc_id     = aws_vpc.wsc2024-prod-vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.wsc2024-prod-natgw-a.id
  }
  
  tags = {
    Name = "wsc2024-prod-app-rt-a"
  }
 }

  resource "aws_route_table_association" "wsc2024-prod-private_association_a" {
  subnet_id      = aws_subnet.wsc2024-prod-app-sn-a.id
  route_table_id = aws_route_table.wsc2024-prod-app-rt-a.id
}

  resource "aws_route_table" "wsc2024-prod-app-rt-b" {
  vpc_id     = aws_vpc.wsc2024-prod-vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.wsc2024-prod-natgw-b.id
  }
  
  tags = {
    Name = "wsc2024-prod-app-rt-b"
  }
 }

 resource "aws_route_table_association" "wsc2024-prod-private_association_b" {
  subnet_id      = aws_subnet.wsc2024-prod-app-sn-b.id
  route_table_id = aws_route_table.wsc2024-prod-app-rt-b.id
}

#
# Create S3 Endpoint
#
resource "aws_vpc_endpoint" "wsc2024-prod-mgmt-sn-s3" {
  vpc_id       = aws_vpc.wsc2024-prod-vpc.id
  service_name = "com.amazonaws.us-east-1.s3"

  tags = {
    Name = "wsc2024-s3-endpoint"
  }
}

#
# S3 Endpoint Routingtable Association
#
resource "aws_vpc_endpoint_route_table_association" "wsc2024-prod-s3_endpoint_rt_a_association" {
  route_table_id  = aws_route_table.wsc2024-prod-app-rt-a.id
  vpc_endpoint_id = aws_vpc_endpoint.wsc2024-prod-mgmt-sn-s3.id
}
resource "aws_vpc_endpoint_route_table_association" "wsc2024-prod-s3_endpoint_rt_b_association" {
  route_table_id  = aws_route_table.wsc2024-prod-app-rt-b.id
  vpc_endpoint_id = aws_vpc_endpoint.wsc2024-prod-mgmt-sn-s3.id
}

#
# ECR Endpoint Security Group
#
resource "aws_security_group" "wsc2024-prod-ecr_endpoint_sg" {
  name        = "wsc2024-prod-ecr-sg"
  description = "wsc2024-prod-ecr-sg"
  vpc_id      = aws_vpc.wsc2024-prod-vpc.id

  tags = {
    Name = "wsc2024-prod-ecr-sg"
  }
}

#
# ECR Endpoint Security Group Rule
#
resource "aws_vpc_security_group_ingress_rule" "wsc2024-prod-ecr_endpoint_sg_ingress" {
  security_group_id = aws_security_group.wsc2024-prod-ecr_endpoint_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = -1
}
resource "aws_vpc_security_group_egress_rule" "wsc2024-prod-ecr_endpoint_sg_egress" {
  security_group_id = aws_security_group.wsc2024-prod-ecr_endpoint_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = -1
}

#
# Create ECR Endpoint
#
resource "aws_vpc_endpoint" "wsc2024-prod-ecr_endpoint_api" {
  vpc_id            = aws_vpc.wsc2024-prod-vpc.id
  service_name      = "com.amazonaws.us-east-1.ecr.api"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.wsc2024-prod-ecr_endpoint_sg.id
  ]

  private_dns_enabled = true
  tags = {
    Name = "wsc2024-prod-ecr-api-endpoint"
  }
}

resource "aws_vpc_endpoint" "wsc2024-prod-ecr_endpoint_dkr" {
  vpc_id            = aws_vpc.wsc2024-prod-vpc.id
  service_name      = "com.amazonaws.us-east-1.ecr.dkr"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.wsc2024-prod-ecr_endpoint_sg.id,
  ]

  private_dns_enabled = true
  tags = {
    Name = "wsc2024-prod-ecr-dkr-endpoint"
  }
}

#
# Create ECR endpoint Subnet Association
#
resource "aws_vpc_endpoint_subnet_association" "wsc2024-prod-ecr_api_endpoint_subnet_association1" {
  vpc_endpoint_id = aws_vpc_endpoint.wsc2024-prod-ecr_endpoint_api.id
  subnet_id       = aws_subnet.wsc2024-prod-app-sn-a.id
}
resource "aws_vpc_endpoint_subnet_association" "wsc2024-prod-ecr_api_endpoint_subnet_association2" {
  vpc_endpoint_id = aws_vpc_endpoint.wsc2024-prod-ecr_endpoint_api.id
  subnet_id       = aws_subnet.wsc2024-prod-app-sn-b.id
}

resource "aws_vpc_endpoint_subnet_association" "wsc2024-prod-ecr_dkr_endpoint_subnet_association1" {
  vpc_endpoint_id = aws_vpc_endpoint.wsc2024-prod-ecr_endpoint_dkr.id
  subnet_id       = aws_subnet.wsc2024-prod-app-sn-a.id
}
resource "aws_vpc_endpoint_subnet_association" "wsc2024-prod-ecr_dkr_endpoint_subnet_association2" {
  vpc_endpoint_id = aws_vpc_endpoint.wsc2024-prod-ecr_endpoint_dkr.id
  subnet_id       = aws_subnet.wsc2024-prod-app-sn-b.id
}