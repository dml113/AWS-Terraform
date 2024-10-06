resource "aws_security_group" "default_groups" {
    name = "default-groups"
    description = "all traffic"
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