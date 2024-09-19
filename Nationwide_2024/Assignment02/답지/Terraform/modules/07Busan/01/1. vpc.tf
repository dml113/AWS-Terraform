resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "wsi-project-vpc"
  }
}

# Public Subnets 생성
resource "aws_subnet" "public_subnet1" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.region}a" 
  map_public_ip_on_launch = true

  tags = {
    Name = "wsi-project-pub-a"
  }
}

resource "aws_subnet" "public_subnet2" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = true

  tags = {
    Name = "wsi-project-pub-b"
  }
}

# Private Subnets 생성
resource "aws_subnet" "private_subnet1" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "${var.region}a"

  tags = {
    Name = "wsi-project-priv-a"
  }
}

resource "aws_subnet" "private_subnet2" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "${var.region}b"

  tags = {
    Name = "wsi-project-priv-b"
  }
}

# Internet Gateway 생성
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "wsi-project-igw"
  }
}

# NAT Gateway 생성
resource "aws_nat_gateway" "nat_gateway1" {
  allocation_id = aws_eip.nat_gateway1[0].id
  subnet_id     = aws_subnet.public_subnet1.id

  tags = {
    Name = "wsi-project-nat-a"
  }
}

resource "aws_nat_gateway" "nat_gateway2" {
  allocation_id = aws_eip.nat_gateway2[0].id
  subnet_id     = aws_subnet.public_subnet2.id

  tags = {
    Name = "wsi-project-nat-b"
  }
}

# NAT Gateway에 할당될 Elastic IP 생성
resource "aws_eip" "nat_gateway1" {
  count = 1
}

resource "aws_eip" "nat_gateway2" {
  count = 1
}

# Public 및 Private Route Tables 생성
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "wsi-project-pub-rt"
  }
}

resource "aws_route_table" "private_route_table1" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway1.id
  }

  tags = {
    Name = "wsi-project-priv-a-rt"
  }
}

resource "aws_route_table" "private_route_table2" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway2.id
  }

  tags = {
    Name = "wsi-project-priv-b-rt"
  }
}

# Public 및 Private Subnet에 Route Table 연결
resource "aws_route_table_association" "public_subnet_association1" {
  subnet_id      = aws_subnet.public_subnet1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_association2" {
  subnet_id      = aws_subnet.public_subnet2.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_subnet_association1" {
  subnet_id      = aws_subnet.private_subnet1.id
  route_table_id = aws_route_table.private_route_table1.id
}

resource "aws_route_table_association" "private_subnet_association2" {
  subnet_id      = aws_subnet.private_subnet2.id
  route_table_id = aws_route_table.private_route_table2.id
}
