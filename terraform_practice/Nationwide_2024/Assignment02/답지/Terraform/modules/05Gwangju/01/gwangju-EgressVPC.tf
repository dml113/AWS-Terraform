#######################################
#               VPC                   #
#######################################
resource "aws_vpc" "vpc" {
    cidr_block = "10.0.2.0/24"

    tags = {
        Name = "gwangju-EgressVPC"
    }
}

#######################################
#               subnet                #
#######################################
resource "aws_subnet" "public_subnet_a" {
    vpc_id = aws_vpc.vpc.id
    cidr_block = "10.0.2.0/28"
    availability_zone = "${var.region}a"
    
    map_public_ip_on_launch = true

    tags = {
        Name = "gwangju-EgressVPC_public_subnet_a"
    }
}

resource "aws_subnet" "private_subnet_a" {
    vpc_id = aws_vpc.vpc.id
    cidr_block = "10.0.2.16/28"
    availability_zone = "${var.region}a"
    tags = {
        Name = "gwangju-EgressVPC_private_subnet_a"
    }
}

resource "aws_subnet" "private_subnet_b" {
    vpc_id = aws_vpc.vpc.id
    cidr_block = "10.0.2.32/28"
    availability_zone = "${var.region}b"
    tags = {
        Name = "gwangju-EgressVPC_private_subnet_b"
    }
}
#######################################
#               gateway               #
#######################################
resource "aws_internet_gateway" "IGW" {
    vpc_id = aws_vpc.vpc.id

    tags = {
      Name = "IGW"
    }
}

resource "aws_eip" "nat-eip1" {
    vpc = true

    lifecycle {
      create_before_destroy = true 
    } 
}

resource "aws_nat_gateway" "nat_gateway-a" {
    allocation_id = aws_eip.nat-eip1.id 
    subnet_id = aws_subnet.public_subnet_a.id 
    tags = {
      Name = "NAT-GW-a"
    }  
}

#######################################
#               route                 #
#######################################
resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.vpc.id 

    tags = {
      Name = "public-rt"
    }  
}

resource "aws_route_table_association" "public_route_table_association_1" {
    subnet_id = aws_subnet.public_subnet_a.id
    route_table_id = aws_route_table.public_rt.id 
}

resource "aws_route_table" "private_rt-a" {
    vpc_id = aws_vpc.vpc.id 

    tags = {
      Name = "private_rt-a"
    }  
}

resource "aws_route_table_association" "private_route_table_association_1" {
    subnet_id = aws_subnet.private_subnet_a.id
    route_table_id = aws_route_table.private_rt-a.id
}

resource "aws_route_table" "private_rt-b" {
    vpc_id = aws_vpc.vpc.id 

    tags = {
      Name = "private_rt-b"
    }  
}

resource "aws_route_table_association" "private_route_table_association_2" {
    subnet_id = aws_subnet.private_subnet_b.id
    route_table_id = aws_route_table.private_rt-b.id
}

resource "aws_route" "igw-connect" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.IGW.id
}

resource "aws_route" "nat-a-connect" {
  route_table_id         = aws_route_table.private_rt-a.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.nat_gateway-a.id
}

resource "aws_route" "nat-b-connect" {
  route_table_id         = aws_route_table.private_rt-b.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.nat_gateway-a.id
}

#
# Create Security_Group
#
  resource "aws_security_group" "Egress_Bastion_Instance_SG" {
  name        = "Egress_bastion-ec2-sg"
  description = "Egress_bastion-ec2-sg"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name = "Egress_bastion-ec2-sg"
  }
}

#
# Create Security_Group_Rule
#

  resource "aws_security_group_rule" "Egress_Bastion_Instance_SG_ingress" {
  type              = "ingress"
  from_port         = -1
  to_port           = -1
  protocol          = "icmp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.Egress_Bastion_Instance_SG.id}"
}
  resource "aws_security_group_rule" "Egress_Bastion_Instance_SG_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.Egress_Bastion_Instance_SG.id}"
}

#
# Create Bastion_Role
#
data "aws_iam_policy_document" "Egress_AdministratorAccessDocument" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy" "AdministratorAccess" {
  arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role" "bastion_role" {
  name               = "warm-bastion-role"
  assume_role_policy = data.aws_iam_policy_document.Egress_AdministratorAccessDocument.json
}

resource "aws_iam_role_policy_attachment" "bastion_policy" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = data.aws_iam_policy.AdministratorAccess.arn
}

#
# Create Bastion_profile
#
resource "aws_iam_instance_profile" "bastion_profiles" {
  name = "bastion_profiles_a"
  role = aws_iam_role.bastion_role.name
}

#
# Create Bastion_Instance
#
  resource "aws_instance" "Egress-Bastion_Instance" {
  subnet_id     = aws_subnet.private_subnet_b.id
  security_groups = [aws_security_group.Egress_Bastion_Instance_SG.id]
  ami           = "ami-01123b84e2a4fba05"
  iam_instance_profile   = aws_iam_instance_profile.bastion_profiles.name
  instance_type = "t3.small"
  tags = {
    Name = "gwangju-EgressVPC-Instance"
  }
}