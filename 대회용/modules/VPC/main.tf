resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_internet_gateway" "this" {
  count = var.create_igw ? 1 : 0
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.vpc_name}-igw"
  }
}

resource "aws_subnet" "this" {
  for_each = var.subnets
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  map_public_ip_on_launch = each.value.public
  tags = {
    Name = each.value.name
  }
}

resource "aws_route_table" "this" {
  for_each = var.route_tables
  vpc_id = aws_vpc.this.id
  tags = {
    Name = each.key
  }
}

# Elastic IP 생성
resource "aws_eip" "this" {
  for_each = var.nat_gateways
  vpc      = true
  tags = {
    Name = each.value.name
  }
}

# NAT Gateway 생성
resource "aws_nat_gateway" "this" {
  for_each       = var.nat_gateways
  subnet_id      = aws_subnet.this[each.value.subnet_id].id
  allocation_id  = aws_eip.this[each.key].id
  tags = {
    Name = each.value.name
  }
}

resource "aws_route" "this" {
  for_each = var.routes
  route_table_id         = aws_route_table.this[each.value.rt_name].id
  destination_cidr_block = each.value.cidr

  gateway_id = lookup(each.value, "gateway_id", null) != null ? each.value.gateway_id : null
  nat_gateway_id = lookup(each.value, "nat_gateway_key", null) != null ? aws_nat_gateway.this[each.value.nat_gateway_key].id : null
}

resource "aws_route_table_association" "this" {
  for_each = var.subnet_associations
  subnet_id      = aws_subnet.this[each.value.subnet_key].id
  route_table_id = aws_route_table.this[each.value.route_table_key].id
}