resource "aws_vpc" "vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support = true
    enable_dns_hostnames = true

    tags = {
        Name = "wsi-vpc"
    }
}

resource "aws_subnet" "private-subnet-a" {
    vpc_id = aws_vpc.vpc.id
    cidr_block = "10.0.3.0/24"
    availability_zone = "${var.region}a"
    
    tags = {
        Name = "wsi-private-a"
    }
}

resource "aws_subnet" "private-subnet-b" {
    vpc_id = aws_vpc.vpc.id
    cidr_block = "10.0.4.0/24"
    availability_zone = "${var.region}b"

    tags = {
        Name = "wsi-private-b"
    }
}

resource "aws_subnet" "public-subnet-a" {
    vpc_id = aws_vpc.vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "${var.region}a"

    map_public_ip_on_launch = true

    tags = {
        Name = "wsi-public-a"
    }
}

resource "aws_subnet" "public-subnet-b" {
    vpc_id = aws_vpc.vpc.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "${var.region}b"

    map_public_ip_on_launch = true

    tags = {
        Name = "wsi-public-b"
    }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.vpc.id 

    tags = {
        Name = "wsi-igw"
    }
} 

resource "aws_eip" "nat-eip1" {
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_eip" "nat-eip2" {
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_nat_gateway" "ngw1" {
    allocation_id = aws_eip.nat-eip1.id
    subnet_id = aws_subnet.public-subnet-a.id

    tags = {
        Name = "wsi-nat-a"
    }
}

resource "aws_nat_gateway" "ngw2" {
    allocation_id = aws_eip.nat-eip2.id 
    subnet_id = aws_subnet.public-subnet-b.id

    tags = {
        Name = "wsi-nat-b"
    }
}

resource "aws_route_table" "public-route-table" {
    vpc_id = aws_vpc.vpc.id

    tags = {
        Name = "wsi-public-rtb"
    }
}

resource "aws_route_table" "private-a-route-table" {
    vpc_id = aws_vpc.vpc.id

    tags = {
        Name = "wsi-private-a-rtb"
    }
}

resource "aws_route_table" "private-b-route-table" {
    vpc_id = aws_vpc.vpc.id

    tags = {
        Name = "wsi-private-b-rtb"
    }
}

resource "aws_route" "public-route" {
    route_table_id = aws_route_table.public-route-table.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
}

resource "aws_route" "private-a-route" {
    route_table_id = aws_route_table.private-a-route-table.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngw1.id
}

resource "aws_route" "private-b-route" {
    route_table_id = aws_route_table.private-b-route-table.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngw2.id
}

resource "aws_route_table_association" "public-route-table-association1" {
    route_table_id = aws_route_table.public-route-table.id
    subnet_id = aws_subnet.public-subnet-a.id 
}

resource "aws_route_table_association" "public-route-table-association2" {
    route_table_id = aws_route_table.public-route-table.id
    subnet_id = aws_subnet.public-subnet-b.id
}

resource "aws_route_table_association" "private-route-table-association1" {
    route_table_id = aws_route_table.private-a-route-table.id
    subnet_id = aws_subnet.private-subnet-a.id
}

resource "aws_route_table_association" "private-route-table-association2" {
    route_table_id = aws_route_table.private-b-route-table.id
    subnet_id = aws_subnet.private-subnet-b.id
}