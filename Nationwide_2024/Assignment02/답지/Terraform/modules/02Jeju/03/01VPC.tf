resource "aws_vpc" "vpc" {
    cidr_block = "210.89.0.0/16"
    enable_dns_support = true
    enable_dns_hostnames = true

    tags = {
        Name = "J-VPC"
    }
}

resource "aws_subnet" "private_subnet_a" {
    vpc_id = aws_vpc.vpc.id
    cidr_block = "210.89.1.0/24"
    availability_zone = "${var.region}a"

    tags = {
        Name = "J-company-priv-sub-a"
    }
}

resource "aws_subnet" "private_subnet_b" {
    vpc_id = aws_vpc.vpc.id
    cidr_block = "210.89.2.0/24"
    availability_zone = "${var.region}b"

    tags = {
        Name = "J-company-priv-sub-b"
    }
}

resource "aws_route_table" "private_a_route_table" {
    vpc_id = aws_vpc.vpc.id

    tags = {
        Name = "J-company-priv-rta"
    }
}

resource "aws_route_table" "private_b_route_table" {
    vpc_id = aws_vpc.vpc.id

    tags = {
        Name = "J-company-priv-rtb"
    }
}

resource "aws_route_table_association" "private_route_table_association_a" {
    route_table_id = aws_route_table.private_a_route_table.id
    subnet_id = aws_subnet.private_subnet_a.id
}

resource "aws_route_table_association" "private_route_table_association_b" {
    route_table_id = aws_route_table.private_b_route_table.id
    subnet_id = aws_subnet.private_subnet_b.id
}