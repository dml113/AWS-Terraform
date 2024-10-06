resource "aws_security_group" "bastion-security-groups" {
    name = "wsi-bastion-sg"
    description = "for bastion ec2"
    vpc_id = aws_vpc.vpc.id

    ingress {
        from_port = 4272
        to_port = 4272
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"] 
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "wsi-bastion-sg"
    }
}

resource "aws_security_group" "all-security-groups" {
    name = "default-groups"
    description = "all inbound and outbound"
    vpc_id = aws_vpc.vpc.id

    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"] 
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "default-groups"
    }
}

resource "aws_security_group" "wsi-app-alb-sg" {
    name = "wsi-app-alb-sg"
    description = "Application Load Balancer Security Groups"
    vpc_id = aws_vpc.vpc.id

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "wsi-app-alb-sg"
    }
}