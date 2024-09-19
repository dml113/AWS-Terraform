resource "aws_vpc" "vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support = true
    enable_dns_hostnames = true

    tags = {
        Name = "serverless-vpc"
    }
}

resource "aws_subnet" "public-subnet-a" {
    vpc_id = aws_vpc.vpc.id
    cidr_block = "10.0.100.0/24"
    availability_zone = "${var.region}a"

    map_public_ip_on_launch = true

    tags = {
        Name = "serverless-public-sn-a"
    }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.vpc.id 

    tags = {
        Name = "igw"
    }
} 

resource "aws_route_table" "public-route-table" {
    vpc_id = aws_vpc.vpc.id

    tags = {
        Name = "serverless-public-rt"
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
    name = "bastion-sg"
    description = "for bastion ec2"
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
        Name = "sg-bastion"
    }
}

resource "aws_iam_role" "example_role" {
    name = "role-bastion"

    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
        "Effect": "Allow",
        "Principal": {
        "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "example_attachment" {
    role       = aws_iam_role.example_role.name
    policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
    name = "ec2_instance_profile"
    role = aws_iam_role.example_role.name
}

resource "tls_private_key" "key" {
    algorithm = "RSA"
    rsa_bits =  4096
}

resource "aws_key_pair" "keypair" {
    key_name   = "bastion-key"
    public_key = tls_private_key.key.public_key_openssh
}

resource "local_file" "downloads_key" {
    filename = "Jeju_bastion.pem"
    content  = tls_private_key.key.private_key_pem
}

data "aws_ami" "amazon_linux" {
  most_recent = true 
  owners = ["amazon"]

  filter {
    name = "name"
    values = ["al2023-ami-*x86*"]
  }
}

resource "aws_instance" "wsi-bastion-instance" {
    subnet_id = aws_subnet.public-subnet-a.id
    vpc_security_group_ids = [aws_security_group.wsi-bastion.id]
    ami = data.aws_ami.amazon_linux.id
    iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name 
    instance_type = "t3.medium"
    key_name = aws_key_pair.keypair.key_name
    tags = {
        Name = "serverless-bastion"
    }
}
