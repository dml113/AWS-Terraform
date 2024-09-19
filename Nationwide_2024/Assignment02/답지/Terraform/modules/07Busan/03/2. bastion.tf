# Create Key-pair
#
resource "tls_private_key" "bastion_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "wsc2024" {
  key_name   = "wsc2024.pem"
  public_key = tls_private_key.bastion_key.public_key_openssh
} 

resource "local_file" "bastion_local" {
  filename        = "wsc2024.pem"
  content         = tls_private_key.bastion_key.private_key_pem
}


data "aws_ami" "webapp_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-*x86*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # Amazon's official account ID
}

resource "aws_security_group" "webapp_sg" {
  vpc_id = var.vpc_id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = [ "::/0" ]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = [ "::/0" ]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = [ "::/0" ]
  }
  tags = {
    "Name" = "bastion-sg"
  }
}

resource "aws_instance" "webapp_instance" {
  ami = data.aws_ami.webapp_ami.id
  subnet_id = var.vpc_subnet_a
  instance_type = "t3.small"
  key_name        = "wsc2024.pem"
  vpc_security_group_ids = [aws_security_group.webapp_sg.id]
  associate_public_ip_address = true
  iam_instance_profile         = aws_iam_instance_profile.webapp_instance_profile.name
  user_data = <<EOF
#!/bin/bash
yum install curl -y --allowerasing
yum install jq -y
EOF
  tags = {
    "Name" = "wsi-bastion"
  }
}

resource "aws_iam_role" "bastion_role" {
  name               = "wsi-bastion-ec2-role3"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action    = "sts:AssumeRole"
    }]
  })
}

# AdministratorAccess 정책 연결
resource "aws_iam_role_policy_attachment" "bastion_role_admin_attachment" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "webapp_instance_profile" {
  name = "wsi-bastion-ec2-profile3"
  role = aws_iam_role.bastion_role.name
}

####################################################################################
###EC2 Server###
resource "aws_instance" "webapp_instance_1" {
  ami = data.aws_ami.webapp_ami.id
  subnet_id = var.vpc_subnet_a
  instance_type = "t3.small"
  key_name        = "wsc2024.pem"
  vpc_security_group_ids = [aws_security_group.webapp_sg.id]
  associate_public_ip_address = true
  iam_instance_profile         = aws_iam_instance_profile.webapp_instance_profile.name
  user_data = <<EOF
#!/bin/bash
yum install docker -y
systemctl enable --now docker
systemctl usermod -aG docker ec2-user
sudo su - ec2-user
yum install -y ruby
yum install wget -y
wget https://aws-codedeploy-ap-northeast-2.s3.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto
rm -rf install
sudo service codedeploy-agent start
EOF
  tags = {
    "Name" = "wsi-server"
  }
}

resource "aws_instance" "webapp_instance_2" {
  ami = data.aws_ami.webapp_ami.id
  subnet_id = var.vpc_subnet_a
  instance_type = "t3.small"
  key_name        = "wsc2024.pem"
  vpc_security_group_ids = [aws_security_group.webapp_sg.id]
  associate_public_ip_address = true
  iam_instance_profile         = aws_iam_instance_profile.webapp_instance_profile.name
  user_data = <<EOF
#!/bin/bash
yum install docker -y
systemctl enable --now docker
systemctl usermod -aG docker ec2-user
sudo su - ec2-user
yum install -y ruby
yum install wget -y
wget https://aws-codedeploy-ap-northeast-2.s3.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto
rm -rf install
sudo service codedeploy-agent start
EOF
  tags = {
    "Name" = "wsi-server"
  }
}