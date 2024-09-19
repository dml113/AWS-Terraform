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

data "aws_availability_zones" "available" {}

resource "aws_security_group" "webapp_sg" {
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 2024
    to_port     = 2024
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    "Name" = "wsi-project-ec2-sg"
  }
}

resource "aws_iam_role" "bastion_role" {
  name               = "wsi-project-ec2-role"
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

resource "aws_iam_role_policy_attachment" "admin_policy_attachment" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "webapp_instance_profile" {
  name = "wsi-project-ec2-role"
  role = aws_iam_role.bastion_role.name
}

resource "aws_instance" "webapp_instance" {
  ami                          = data.aws_ami.webapp_ami.id
  subnet_id                    = aws_subnet.public_subnet2.id
  availability_zone            = element(data.aws_availability_zones.available.names, 1)
  instance_type                = "t3.micro"
  vpc_security_group_ids       = [aws_security_group.webapp_sg.id]
  associate_public_ip_address  = true
  iam_instance_profile         = aws_iam_instance_profile.webapp_instance_profile.name

  user_data = <<EOF
#!/bin/bash
sed -i 's|.*PasswordAuthentication.*|PasswordAuthentication yes|g' /etc/ssh/sshd_config
systemctl restart sshd
echo 'Skills2024**' | passwd --stdin ec2-user
sudo sed -i 's/#Port 22/Port 2024/g' /etc/ssh/sshd_config
sudo systemctl restart sshd
yum install jq -y
yum install curl -y
yum install git -y
EOF

  tags = {
    "Name" = "wsi-project-ec2"
  }
}

resource "aws_eip" "example" {
  vpc = true

  tags = {
    "Name" = "wsi-project-ec2-eip"
  }
}

resource "aws_eip_association" "example" {
  instance_id   = aws_instance.webapp_instance.id
  allocation_id = aws_eip.example.id
}
