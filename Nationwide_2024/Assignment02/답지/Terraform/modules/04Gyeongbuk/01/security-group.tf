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

resource "aws_security_group" "ecs-wsi-alb" {
    name = "ecs-wsi-sg-alb"
    description = "ecs-wsi-alb"
    vpc_id = aws_vpc.vpc.id

    ingress {
        from_port = 80
        to_port = 80
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
        Name = "ecs-wsi-sg-alb"
    }
}

