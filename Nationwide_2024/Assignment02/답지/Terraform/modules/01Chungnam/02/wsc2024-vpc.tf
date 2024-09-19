resource "aws_default_vpc" "default_vpc" {
}

resource "aws_default_subnet" "default_vpc_subnet_a" {
    availability_zone = "us-west-1a"
}

resource "aws_default_subnet" "default_vpc_subnet_b" {
    availability_zone = "us-west-1b"
}