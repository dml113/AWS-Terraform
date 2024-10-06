provider "aws" {
    region = "ap-northeast-2"
}

resource "aws_default_vpc" "default_vpc" {
}

resource "aws_default_subnet" "default_vpc_subnet_a" {
    availability_zone = "ap-northeast-2a"
}

resource "aws_default_subnet" "default_vpc_subnet_b" {
    availability_zone = "ap-northeast-2b"
}

resource "aws_default_subnet" "default_vpc_subnet_c" {
    availability_zone = "ap-northeast-2c"
}

resource "aws_default_subnet" "default_vpc_subnet_d" {
    availability_zone = "ap-northeast-2d"
}