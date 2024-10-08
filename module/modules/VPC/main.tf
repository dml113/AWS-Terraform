resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "public" {
  count                = length(var.public_subnets_cidr)
  vpc_id               = aws_vpc.vpc.id
  cidr_block           = var.public_subnets_cidr[count.index]
  availability_zone    = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = var.public_subnet_names[count.index]
  }
}

resource "aws_subnet" "private" {
  count                = length(var.private_subnets_cidr)
  vpc_id               = aws_vpc.vpc.id
  cidr_block           = var.private_subnets_cidr[count.index]
  availability_zone    = var.availability_zones[count.index]

  tags = {
    Name = var.private_subnet_names[count.index]
  }
}

# resource "aws_subnet" "data" {
#   count                = length(var.data_subnets_cidr)
#   vpc_id               = aws_vpc.vpc.id
#   cidr_block           = var.data_subnets_cidr[count.index]
#   availability_zone    = var.availability_zones[count.index]

#   tags = {
#     Name = var.data_subnet_names[count.index]
#   }
# }

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = var.igw_name
  }
}

resource "aws_eip" "nat_eip" {
  count = 2
  domain = "vpc"

  tags = {
    Name = var.nat_eip_names[count.index]
  }
}

resource "aws_nat_gateway" "natgw" {
  count = 2
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = var.nat_gw_names[count.index]
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = var.public_route_table_name
  }
}

resource "aws_route_table_association" "public_rt_assoc" {
  count          = length(var.public_subnets_cidr)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt" {
  count = 2
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.natgw[count.index].id
  }

  tags = {
    Name = var.private_route_table_names[count.index]
  }
}

resource "aws_route_table_association" "private_rt_assoc" {
  count          = length(var.private_subnets_cidr)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_rt[count.index].id
}

# resource "aws_route_table" "data_rt" {
#   count = length(var.data_subnets_cidr)
#   vpc_id = aws_vpc.vpc.id

#   tags = {
#     Name = var.data_route_table_names[count.index]
#   }
# }

# resource "aws_route_table_association" "data_rt_assoc" {
#   count          = length(var.data_subnets_cidr)
#   subnet_id      = aws_subnet.data[count.index].id
#   route_table_id = aws_route_table.data_rt[count.index].id
# }