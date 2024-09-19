resource "aws_vpc" "vpc" {
    cidr_block = "10.150.0.0/16"
    enable_dns_support = true
    enable_dns_hostnames = true

    tags = {
        Name = "wsi-vpc"
    }
}

resource "aws_subnet" "public-subnet-a" {
    vpc_id = aws_vpc.vpc.id
    cidr_block = "10.150.10.0/24"
    availability_zone = "${var.region}a"

    map_public_ip_on_launch = true

    tags = {
        Name = "wsi-public-a"
    }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.vpc.id 

    tags = {
        Name = "wsi-igw"
    }
} 

resource "aws_route_table" "public-route-table" {
    vpc_id = aws_vpc.vpc.id

    tags = {
        Name = "wsi-public-rt"
    }
}

resource "aws_route" "public-route" {
    route_table_id = aws_route_table.public-route-table.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public-route-table-association1" {
    route_table_id = aws_route_table.public-route-table.id
    subnet_id = aws_subnet.public-subnet-a.id 
}

data "http" "myip" {
    url = "https://ipv4.icanhazip.com"
}

resource "aws_security_group" "wsi-bastion" {
    name = "wsi-sg-bastion"
    description = "for wsi-bastion ec2"
    vpc_id = aws_vpc.vpc.id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"] 
    }

    egress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "wsi-sg-bastion"
    }
}