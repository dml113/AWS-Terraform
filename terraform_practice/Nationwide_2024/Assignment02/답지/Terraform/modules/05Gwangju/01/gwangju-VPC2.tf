#######################################
#               VPC                   #
#######################################
resource "aws_vpc" "gwangju_VPC2" {
    cidr_block = "10.0.1.0/24"

    tags = {
        Name = "gwangju-VPC2"
    }
}

#######################################
#               subnet                #
#######################################
resource "aws_subnet" "gwangju_VPC2_private_subnet_a" {
    vpc_id = aws_vpc.gwangju_VPC2.id
    cidr_block = "10.0.1.32/28"
    availability_zone = "${var.region}a"
    tags = {
        Name = "gwangju_VPC2_private_subnet_a"
    }
}

resource "aws_subnet" "gwangju_VPC2_private_subnet_b" {
    vpc_id = aws_vpc.gwangju_VPC2.id
    cidr_block = "10.0.1.64/28"
    availability_zone = "${var.region}b"
    tags = {
        Name = "gwangju_VPC2_private_subnet_b"
    }
}
#######################################
#               route                 #
#######################################
resource "aws_route_table" "gwangju_VPC2_private_rt-a" {
    vpc_id = aws_vpc.gwangju_VPC2.id 

    tags = {
      Name = "gwangju_VPC2_private_rt-a"
    }  
}

resource "aws_route_table_association" "gwangju_VPC2_private_route_table_association_1" {
    subnet_id = aws_subnet.gwangju_VPC2_private_subnet_a.id
    route_table_id = aws_route_table.gwangju_VPC2_private_rt-a.id
}

resource "aws_route_table" "gwangju_VPC2_private_rt-b" {
    vpc_id = aws_vpc.gwangju_VPC2.id 

    tags = {
      Name = "gwangju_VPC2_private_rt-b"
    }  
}

resource "aws_route_table_association" "gwangju_VPC2_private_route_table_association_2" {
    subnet_id = aws_subnet.gwangju_VPC2_private_subnet_b.id
    route_table_id = aws_route_table.gwangju_VPC2_private_rt-b.id
}

 resource "aws_security_group" "VPC2_Bastion_Instance_SG" {
  name        = "VPC2_bastion-ec2-sg"
  description = "VPC2_bastion-ec2-sg"
  vpc_id      = aws_vpc.gwangju_VPC2.id

  tags = {
    Name = "VPC2_bastion-ec2-sg"
  }
}

  resource "aws_security_group_rule" "VPC2_Bastion_Instance_SG_ingress" {
  type              = "ingress"
  from_port         = -1
  to_port           = -1
  protocol          = "icmp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.VPC2_Bastion_Instance_SG.id}"
}
  resource "aws_security_group_rule" "VPC2_Bastion_Instance_SG_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.VPC2_Bastion_Instance_SG.id}"
}

  resource "aws_instance" "VPC2-Bastion_Instance" {
  subnet_id     = aws_subnet.gwangju_VPC2_private_subnet_a.id
  security_groups = [aws_security_group.VPC2_Bastion_Instance_SG.id]
  ami           = "ami-01123b84e2a4fba05" #amazonlinux2023
  iam_instance_profile   = aws_iam_instance_profile.bastion_profiles.name
  instance_type = "t3.small"
  user_data = <<EOF
#!/bin/bash
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
echo 'Skill53##' | passwd --stdin ec2-user
echo 'AuthenticationMethods password,publickey' >> /etc/ssh/sshd_config
systemctl restart sshd
EOF
  tags = {
    Name = "gwangju-VPC2-Instance"
  }
}